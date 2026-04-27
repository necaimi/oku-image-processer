import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oku_image_processer/providers/file_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  group('FileListNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('addFiles extracts correct filename and relative path for single files', () async {
      final notifier = container.read(fileListProvider.notifier);
      
      // Create a temporary file to test with
      final tempDir = Directory.systemTemp.createTempSync();
      final testFile = File(p.join(tempDir.path, 'test_image.jpg'));
      testFile.writeAsBytesSync([0, 1, 2, 3]);

      try {
        final xFile = XFile(testFile.path);
        
        await notifier.addFiles([xFile]);
        
        final state = container.read(fileListProvider);
        expect(state.files.length, 1);
        expect(state.files[0].name, 'test_image.jpg');
        expect(state.files[0].relativePath, 'test_image.jpg');
        expect(state.files[0].file.path, testFile.path);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('addFiles handles absolute paths in names correctly (regression test)', () async {
      // This test simulates the issue where XFile might have an absolute path as its name
      // although we mostly care about xFile.path being absolute and ensuring we extract the basename.
      final notifier = container.read(fileListProvider.notifier);
      
      final tempDir = Directory.systemTemp.createTempSync();
      // Use a path that looks like a deep absolute path
      final testFilePath = p.join(tempDir.path, 'sub', 'deep', 'image.png');
      Directory(p.dirname(testFilePath)).createSync(recursive: true);
      final testFile = File(testFilePath);
      testFile.writeAsBytesSync([0, 1, 2, 3]);

      try {
        final xFile = XFile(testFile.path);
        
        await notifier.addFiles([xFile]);
        
        final state = container.read(fileListProvider);
        expect(state.files.length, 1);
        expect(state.files[0].name, 'image.png');
        expect(state.files[0].relativePath, 'image.png');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
