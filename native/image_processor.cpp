#ifdef _WIN32
#define NOMINMAX
#define _CRT_SECURE_NO_WARNINGS
#define STBI_WINDOWS_UTF8
#define STBIW_WINDOWS_UTF8
#include <windows.h>
#endif

#include "image_processor.h"
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>

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
// Returns 0 on success, negative error code on failure
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

// Callback for writing to a memory buffer
static void stbi_mem_write_func(void* context, void* data, int size) {
    std::vector<uint8_t>* buffer = (std::vector<uint8_t>*)context;
    uint8_t* u8data = (uint8_t*)data;
    buffer->insert(buffer->end(), u8data, u8data + size);
}

extern "C" int process_image(
    const char* input_path, 
    const char* output_path, 
    int target_width, 
    int target_height, 
    int quality,
    int format
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

    int write_res = -88;
    if (format == 1) { // PNG
        int len = 0;
        unsigned char* png_mem = stbi_write_png_to_mem(output_pixels.data(), final_w * 4, final_w, final_h, 4, &len);
        if (png_mem) {
            write_res = write_to_file_internal(output_path, png_mem, len);
            STBIW_FREE(png_mem);
        } else {
            write_res = -21;
        }
    } 
    else if (format == 2) { // WebP
        uint8_t* webp_data = nullptr;
        size_t webp_size = WebPEncodeRGBA(output_pixels.data(), final_w, final_h, final_w * 4, (float)quality, &webp_data);
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
        write_res = -24; // Unsupported format
    }

    return write_res;
}
