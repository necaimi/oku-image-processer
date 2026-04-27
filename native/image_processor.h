#ifndef IMAGE_PROCESSOR_H
#define IMAGE_PROCESSOR_H

#ifdef _WIN32
#define FFI_EXPORT __declspec(dllexport)
#else
#define FFI_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 高性能图像处理接口
 * @param input_path 输入路径
 * @param output_path 输出路径
 * @param width 目标宽度
 * @param height 目标高度
 * @param quality 压缩质量 (1-100)
 * @param format 目标格式 (0: jpg, 1: png, 2: webp)
 * @return 0 表示成功，非 0 表示错误代码
 */
FFI_EXPORT int process_image(
    const char* input_path, 
    const char* output_path, 
    int width, 
    int height, 
    int quality,
    int format
);

#ifdef __cplusplus
}
#endif

#endif // IMAGE_PROCESSOR_H
