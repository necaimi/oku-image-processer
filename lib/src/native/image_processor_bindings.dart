import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

// 定义 C 函数的签名
typedef ProcessImageC = ffi.Int32 Function(
  ffi.Pointer<Utf8> inputPath,
  ffi.Pointer<Utf8> outputPath,
  ffi.Int32 width,
  ffi.Int32 height,
  ffi.Int32 quality,
  ffi.Int32 format,
  ffi.Int32 enableWm,
  ffi.Int32 wmType,
  ffi.Pointer<Utf8> wmText,
  ffi.Pointer<Utf8> wmImagePath,
  ffi.Float wmOpacity,
  ffi.Int32 wmPosition,
  ffi.Float wmScale,
  ffi.Int32 wmFontSize,
  ffi.Float wmSpacing,
);

// 定义 Dart 函数的签名
typedef ProcessImageDart = int Function(
  ffi.Pointer<Utf8> inputPath,
  ffi.Pointer<Utf8> outputPath,
  int width,
  int height,
  int quality,
  int format,
  int enableWm,
  int wmType,
  ffi.Pointer<Utf8> wmText,
  ffi.Pointer<Utf8> wmImagePath,
  double wmOpacity,
  int wmPosition,
  double wmScale,
  int wmFontSize,
  double wmSpacing,
);

class ImageProcessor {
  late final ffi.DynamicLibrary _lib;
  late final ProcessImageDart _processImage;

  ImageProcessor() {
    _lib = _loadLibrary();
    _processImage = _lib
        .lookup<ffi.NativeFunction<ProcessImageC>>('process_image')
        .asFunction();
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      // 在子线程（Isolate）中，有时无法直接通过文件名找到 DLL
      // 使用 resolvedExecutable 获取程序所在目录，从而获得 DLL 的绝对路径
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final dllPath = p.join(exeDir, 'image_processor.dll');
      
      if (File(dllPath).existsSync()) {
        return ffi.DynamicLibrary.open(dllPath);
      } else {
        // 回退到普通加载
        return ffi.DynamicLibrary.open('image_processor.dll');
      }
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libimage_processor.dylib');
    } else {
      return ffi.DynamicLibrary.open('libimage_processor.so');
    }
  }

  int process(
    String inputPath,
    String outputPath,
    int width,
    int height,
    int quality,
    int format,
    bool enableWm,
    int wmType,
    String wmText,
    String? wmImagePath,
    double wmOpacity,
    int wmPosition,
    double wmScale,
    int wmFontSize,
    double wmSpacing,
  ) {
    final inputPtr = inputPath.toNativeUtf8();
    final outputPtr = outputPath.toNativeUtf8();
    final wmTextPtr = wmText.toNativeUtf8();
    final wmImagePathPtr = (wmImagePath ?? '').toNativeUtf8();

    try {
      return _processImage(
        inputPtr, 
        outputPtr, 
        width, 
        height, 
        quality, 
        format,
        enableWm ? 1 : 0,
        wmType,
        wmTextPtr,
        wmImagePathPtr,
        wmOpacity,
        wmPosition,
        wmScale,
        wmFontSize,
        wmSpacing,
      );
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtr);
      malloc.free(wmTextPtr);
      malloc.free(wmImagePathPtr);
    }
  }
}

// 单例管理逻辑
final imageProcessor = ImageProcessor();
