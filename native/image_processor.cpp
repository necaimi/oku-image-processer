#ifdef _WIN32
#define NOMINMAX
#define _CRT_SECURE_no_WARNINGS
#define STBI_WINDOWS_UTF8
#define STBIW_WINDOWS_UTF8
#include <windows.h>
#endif

#include "image_processor.h"
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cstdint>

// Include WebP encoding headers
#include <webp/encode.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"

#ifdef _WIN32
static std::wstring utf8_to_wide(const char* str) {
    if (!str) return L"";
    int len = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);
    if (len <= 0) return L"";
    std::wstring wstr(len, 0);
    MultiByteToWideChar(CP_UTF8, 0, str, -1, &wstr[0], len);
    if (!wstr.empty() && wstr.back() == L'\0') {
        wstr.pop_back();
    }
    return wstr;
}
#endif

// Helper: Write data to file
static int write_to_file_internal(const char* path, const uint8_t* data, size_t size) {
    if (!path || !data || size == 0) return -101;
#ifdef _WIN32
    std::wstring wpath = utf8_to_wide(path);
    if (wpath.empty()) return -102;
    FILE* f = _wfopen(wpath.c_str(), L"wb");
#else
    FILE* f = fopen(path, "wb");
#endif
    if (!f) return -103;
    size_t written = fwrite(data, 1, size, f);
    fclose(f);
    return (written == size) ? 0 : -104;
}

static void stbi_mem_write_func(void* context, void* data, int size) {
    std::vector<uint8_t>* buffer = (std::vector<uint8_t>*)context;
    uint8_t* u8data = (uint8_t*)data;
    buffer->insert(buffer->end(), u8data, u8data + size);
}

// Simple Alpha Blending
static void blend_rgba(unsigned char* dst, int dw, int dh, const unsigned char* src, int sw, int sh, int x, int y, float opacity) {
    for (int i = 0; i < sh; ++i) {
        int dy = y + i;
        if (dy < 0 || dy >= dh) continue;
        for (int j = 0; j < sw; ++j) {
            int dx = x + j;
            if (dx < 0 || dx >= dw) continue;

            unsigned char* dp = &dst[(dy * dw + dx) * 4];
            const unsigned char* sp = &src[(i * sw + j) * 4];

            float src_a = (sp[3] / 255.0f) * opacity;
            float inv_a = 1.0f - src_a;

            dp[0] = (unsigned char)(src_a * sp[0] + inv_a * dp[0]);
            dp[1] = (unsigned char)(src_a * sp[1] + inv_a * dp[1]);
            dp[2] = (unsigned char)(src_a * sp[2] + inv_a * dp[2]);
            
            float dst_a = dp[3] / 255.0f;
            dp[3] = (unsigned char)((src_a + dst_a * inv_a) * 255.0f);
        }
    }
}

#ifdef _WIN32
// Render Text to RGBA buffer using Windows GDI
static unsigned char* render_text_gdi(const char* text, int font_size, int angle_deg, int* out_w, int* out_h) {
    std::wstring wtext = utf8_to_wide(text);
    if (wtext.empty()) return nullptr;

    HDC hdc = CreateCompatibleDC(NULL);
    // lfEscapement and lfOrientation are in tenths of degrees
    HFONT hFont = CreateFontW(
        -font_size, 0, angle_deg * 10, angle_deg * 10, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Microsoft YaHei"
    );
    SelectObject(hdc, hFont);

    // Calculate bounding box for rotated text
    // For simplicity with rotated text, we use a larger canvas and then crop or just use it
    // A more precise way is to use GetTextExtentPoint32 and math, but here we just need enough space
    int canvas_size = font_size * (int)wtext.length() * 2;
    if (canvas_size < 200) canvas_size = 200;

    RECT rect = {0, 0, canvas_size, canvas_size};
    
    BITMAPINFO bmi = {0};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = canvas_size;
    bmi.bmiHeader.biHeight = -canvas_size; 
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    HBITMAP hbm = CreateDIBSection(hdc, &bmi, DIB_RGB_COLORS, &bits, NULL, 0);
    SelectObject(hdc, hbm);

    memset(bits, 0, canvas_size * canvas_size * 4);
    SetTextColor(hdc, RGB(255, 255, 255));
    SetBkMode(hdc, TRANSPARENT);
    
    // Draw at center to avoid clipping when rotated
    TextOutW(hdc, canvas_size/4, canvas_size/2, wtext.c_str(), (int)wtext.length());

    // Find actual content bounds to crop
    int min_x = canvas_size, max_x = 0, min_y = canvas_size, max_y = 0;
    unsigned char* bgra = (unsigned char*)bits;
    bool found = false;
    for (int y = 0; y < canvas_size; ++y) {
        for (int x = 0; x < canvas_size; ++x) {
            if (bgra[(y * canvas_size + x) * 4] > 0) {
                if (x < min_x) min_x = x;
                if (x > max_x) max_x = x;
                if (y < min_y) min_y = y;
                if (y > max_y) max_y = y;
                found = true;
            }
        }
    }

    if (!found) {
        DeleteObject(hbm);
        DeleteObject(hFont);
        DeleteDC(hdc);
        return nullptr;
    }

    // Add some padding
    min_x = std::max(0, min_x - 5);
    min_y = std::max(0, min_y - 5);
    max_x = std::min(canvas_size - 1, max_x + 5);
    max_y = std::min(canvas_size - 1, max_y + 5);

    int w = max_x - min_x + 1;
    int h = max_y - min_y + 1;
    unsigned char* rgba = (unsigned char*)malloc(w * h * 4);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int src_idx = ((min_y + y) * canvas_size + (min_x + x)) * 4;
            int dst_idx = (y * w + x) * 4;
            rgba[dst_idx + 0] = 255;
            rgba[dst_idx + 1] = 255;
            rgba[dst_idx + 2] = 255;
            rgba[dst_idx + 3] = bgra[src_idx]; // Alpha from brightness
        }
    }

    DeleteObject(hbm);
    DeleteObject(hFont);
    DeleteDC(hdc);

    *out_w = w;
    *out_h = h;
    return rgba;
}
#endif

extern "C" int process_image(
    const char* input_path, 
    const char* output_path, 
    int target_width, 
    int target_height, 
    int quality,
    int format,
    int enable_wm,
    int wm_type,
    const char* wm_text,
    const char* wm_image_path,
    float wm_opacity,
    int wm_position,
    float wm_scale,
    int wm_font_size,
    float wm_spacing
) {
    if (!input_path || !output_path) return -1;

    int width, height, channels;
    unsigned char* input_pixels = nullptr;

#ifdef _WIN32
    std::wstring w_input_path = utf8_to_wide(input_path);
    if (w_input_path.empty()) return -10;
    FILE* f_in = _wfopen(w_input_path.c_str(), L"rb");
    if (!f_in) return -11;
    input_pixels = stbi_load_from_file(f_in, &width, &height, &channels, 4);
    fclose(f_in);
#else
    input_pixels = stbi_load(input_path, &width, &height, &channels, 4);
#endif

    if (!input_pixels) return -12;

    int final_w = target_width;
    int final_h = target_height;
    if (target_width > 0 && target_height <= 0) {
        final_h = (int)((float)target_width * ((float)height / (float)width));
    } else if (target_height > 0 && target_width <= 0) {
        final_w = (int)((float)target_height * ((float)width / (float)height));
    } else if (target_width <= 0 && target_height <= 0) {
        final_w = width;
        final_h = height;
    }
    final_w = std::max(1, final_w);
    final_h = std::max(1, final_h);

    std::vector<unsigned char> output_pixels(final_w * final_h * 4);
    stbir_resize_uint8_linear(input_pixels, width, height, 0, output_pixels.data(), final_w, final_h, 0, STBIR_RGBA);
    stbi_image_free(input_pixels);

    // --- Watermark Logic ---
    if (enable_wm) {
        unsigned char* wm_pixels = nullptr;
        int ww = 0, wh = 0;
        int angle = (wm_position == 9) ? 45 : 0; // Tile mode uses 45 degree

        if (wm_type == 1 && wm_image_path && strlen(wm_image_path) > 0) { // Image
            int wc;
#ifdef _WIN32
            std::wstring w_wm_path = utf8_to_wide(wm_image_path);
            FILE* f_wm = _wfopen(w_wm_path.c_str(), L"rb");
            if (f_wm) {
                wm_pixels = stbi_load_from_file(f_wm, &ww, &wh, &wc, 4);
                fclose(f_wm);
            }
#else
            wm_pixels = stbi_load(wm_image_path, &ww, &wh, &wc, 4);
#endif
            if (wm_pixels) {
                int sww = (int)(final_w * wm_scale);
                int swh = (int)(wh * ((float)sww / ww));
                if (sww > 0 && swh > 0) {
                    std::vector<unsigned char> scaled_wm(sww * swh * 4);
                    stbir_resize_uint8_linear(wm_pixels, ww, wh, 0, scaled_wm.data(), sww, swh, 0, STBIR_RGBA);
                    stbi_image_free(wm_pixels);
                    
                    wm_pixels = (unsigned char*)malloc(sww * swh * 4);
                    memcpy(wm_pixels, scaled_wm.data(), sww * swh * 4);
                    ww = sww; wh = swh;
                } else {
                    stbi_image_free(wm_pixels);
                    wm_pixels = nullptr;
                }
            }
        } 
        else if (wm_type == 0 && wm_text && strlen(wm_text) > 0) { // Text
#ifdef _WIN32
            wm_pixels = render_text_gdi(wm_text, wm_font_size, angle, &ww, &wh);
#endif
        }

        if (wm_pixels) {
            if (wm_position == 9) { // Tile Mode (Full Screen Repeat with Stagger)
                int step_x = ww + (int)(ww * wm_spacing);
                int step_y = wh + (int)(wh * wm_spacing);
                
                for (int y = -wh; y < final_h + wh; y += step_y) {
                    bool is_even_row = ((y / step_y) % 2 == 0);
                    int offset_x = is_even_row ? (step_x / 2) : 0;
                    
                    for (int x = -ww; x < final_w + ww; x += step_x) {
                        blend_rgba(output_pixels.data(), final_w, final_h, wm_pixels, ww, wh, x + offset_x, y, wm_opacity);
                    }
                }
            } else { // Grid Mode
                int px = 0, py = 0;
                int margin = 20;
                switch (wm_position) {
                    case 0: px = margin; py = margin; break;
                    case 1: px = (final_w - ww) / 2; py = margin; break;
                    case 2: px = final_w - ww - margin; py = margin; break;
                    case 3: px = margin; py = (final_h - wh) / 2; break;
                    case 4: px = (final_w - ww) / 2; py = (final_h - wh) / 2; break;
                    case 5: px = final_w - ww - margin; py = (final_h - wh) / 2; break;
                    case 6: px = margin; py = final_h - wh - margin; break;
                    case 7: px = (final_w - ww) / 2; py = final_h - wh - margin; break;
                    case 8: px = final_w - ww - margin; py = final_h - wh - margin; break;
                }
                blend_rgba(output_pixels.data(), final_w, final_h, wm_pixels, ww, wh, px, py, wm_opacity);
            }
            free(wm_pixels);
        }
    }

    // --- Write Logic ---
    int write_res = -88;
    if (format == 1 || format == 3) { // PNG or ICO
        int len = 0;
        unsigned char* png_mem = stbi_write_png_to_mem(output_pixels.data(), final_w * 4, final_w, final_h, 4, &len);
        if (png_mem) {
            if (format == 3) { // ICO Header Wrapping
                std::vector<uint8_t> ico_data;
                ico_data.reserve(len + 22);
                
                // Header (6 bytes)
                ico_data.push_back(0); ico_data.push_back(0); // Reserved
                ico_data.push_back(1); ico_data.push_back(0); // Type (1 for icon)
                ico_data.push_back(1); ico_data.push_back(0); // Count (1 image)
                
                // Directory Entry (16 bytes)
                ico_data.push_back(final_w >= 256 ? 0 : (uint8_t)final_w);
                ico_data.push_back(final_h >= 256 ? 0 : (uint8_t)final_h);
                ico_data.push_back(0); // Color count
                ico_data.push_back(0); // Reserved
                ico_data.push_back(1); ico_data.push_back(0); // Planes
                ico_data.push_back(32); ico_data.push_back(0); // BitCount
                
                uint32_t size = (uint32_t)len;
                ico_data.push_back(size & 0xFF);
                ico_data.push_back((size >> 8) & 0xFF);
                ico_data.push_back((size >> 16) & 0xFF);
                ico_data.push_back((size >> 24) & 0xFF);
                
                uint32_t offset = 22;
                ico_data.push_back(offset & 0xFF);
                ico_data.push_back((offset >> 8) & 0xFF);
                ico_data.push_back((offset >> 16) & 0xFF);
                ico_data.push_back((offset >> 24) & 0xFF);
                
                ico_data.insert(ico_data.end(), png_mem, png_mem + len);
                write_res = write_to_file_internal(output_path, ico_data.data(), ico_data.size());
            } else {
                write_res = write_to_file_internal(output_path, png_mem, len);
            }
            STBIW_FREE(png_mem);
        } else {
            write_res = -21;
        }
    } 
    else if (format == 2) { // WebP
        uint8_t* webp_data = nullptr;
        size_t webp_size = 0;
        webp_size = WebPEncodeRGBA(output_pixels.data(), final_w, final_h, final_w * 4, (float)quality, &webp_data);
        if (webp_size > 0 && webp_data != nullptr) {
            write_res = write_to_file_internal(output_path, webp_data, webp_size);
            WebPFree(webp_data);
        } else {
            write_res = -22;
        }
    } 
    else if (format == 0) { // JPG
        std::vector<unsigned char> rgb_pixels(final_w * final_h * 3);
        for (int i = 0; i < final_w * final_h; ++i) {
            rgb_pixels[i * 3 + 0] = output_pixels[i * 4 + 0];
            rgb_pixels[i * 3 + 1] = output_pixels[i * 4 + 1];
            rgb_pixels[i * 3 + 2] = output_pixels[i * 4 + 2];
        }
        std::vector<uint8_t> jpg_buffer;
        if (stbi_write_jpg_to_func(stbi_mem_write_func, &jpg_buffer, final_w, final_h, 3, rgb_pixels.data(), quality)) {
            write_res = write_to_file_internal(output_path, jpg_buffer.data(), jpg_buffer.size());
        } else {
            write_res = -23;
        }
    }
    else {
        write_res = -24;
    }

    return write_res;
}
