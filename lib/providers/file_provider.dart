import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class SelectedFile {
  final XFile file;
  final int size;
  final String name;
  final String relativePath; // 相对于拖入根目录的路径
  final String sourceRoot;   // 新增：拖入时的原始根路径（目录或文件本身）

  SelectedFile({
    required this.file,
    required this.size,
    required this.name,
    required this.relativePath,
    required this.sourceRoot,
  });
}

class FileListState {
  final List<SelectedFile> files;
  final bool isScanning;

  FileListState({this.files = const [], this.isScanning = false});

  FileListState copyWith({List<SelectedFile>? files, bool? isScanning}) {
    return FileListState(
      files: files ?? this.files,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class FileListNotifier extends Notifier<FileListState> {
  @override
  FileListState build() {
    return FileListState();
  }

  Future<void> addFiles(List<XFile> newFiles) async {
    state = state.copyWith(isScanning: true);
    
    final List<SelectedFile> buffer = [];
    final supportedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        state = state.copyWith(
          files: [...state.files, ...buffer],
        );
        buffer.clear();
      }
    }

    try {
      for (var xFile in newFiles) {
        final String rootPath = p.normalize(xFile.path);

        if (await FileSystemEntity.isDirectory(rootPath)) {
          final dir = Directory(rootPath);
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final String fullPath = p.normalize(entity.path);
              final pathLower = fullPath.toLowerCase();
              if (supportedExtensions.any((ext) => pathLower.endsWith(ext))) {
                final size = await entity.length();
                // Calculate path relative to the dropped directory itself
                final relPath = p.relative(fullPath, from: rootPath);
                
                buffer.add(SelectedFile(
                  file: XFile(fullPath),
                  size: size,
                  name: p.basename(fullPath),
                  relativePath: relPath,
                  sourceRoot: rootPath,
                ));
                if (buffer.length >= 50) flushBuffer();
              }
            }
          }
        } else {
          final String fullPath = p.normalize(xFile.path);
          final pathLower = fullPath.toLowerCase();
          if (supportedExtensions.any((ext) => pathLower.endsWith(ext))) {
            final size = await xFile.length();
            final fileName = p.basename(fullPath);
            buffer.add(SelectedFile(
              file: xFile,
              size: size,
              name: fileName,
              relativePath: fileName, // 单个文件，相对路径就是文件名
              sourceRoot: fullPath,
            ));
            if (buffer.length >= 50) flushBuffer();
          }
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      flushBuffer();
      state = state.copyWith(isScanning: false);
    }
  }

  void removeFile(int index) {
    state = state.copyWith(
      files: [
        for (int i = 0; i < state.files.length; i++)
          if (i != index) state.files[i],
      ],
    );
  }

  void clear() => state = FileListState();
}

final fileListProvider = NotifierProvider<FileListNotifier, FileListState>(FileListNotifier.new);
