import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ImageFormat { jpg, png, webp }
enum ExportMode { newDirectory, overwrite }
enum DimensionLock { none, width, height }

class ProcessingSettings {
  final ImageFormat format;
  final ExportMode exportMode;
  final String? customOutputPath;
  final int width;
  final int height;
  final double quality;
  final bool lockAspectRatio;
  final double aspectRatio; 
  final DimensionLock dimensionLock;
  final String language;
  final double fontSizeFactor;

  ProcessingSettings({
    this.format = ImageFormat.jpg,
    this.exportMode = ExportMode.newDirectory,
    this.customOutputPath,
    this.width = 1920,
    this.height = 1080,
    this.quality = 0.8,
    this.lockAspectRatio = true,
    this.dimensionLock = DimensionLock.none,
    this.language = 'zh',
    this.fontSizeFactor = 1.0,
    double? aspectRatio,
  }) : aspectRatio = aspectRatio ?? (1920 / 1080);

  Map<String, dynamic> toJson() => {
    'format': format.index,
    'exportMode': exportMode.index,
    'customOutputPath': customOutputPath,
    'width': width,
    'height': height,
    'quality': quality,
    'lockAspectRatio': lockAspectRatio,
    'aspectRatio': aspectRatio,
    'dimensionLock': dimensionLock.index,
    'language': language,
    'fontSizeFactor': fontSizeFactor,
  };

  factory ProcessingSettings.fromJson(Map<String, dynamic> json) {
    return ProcessingSettings(
      format: ImageFormat.values[json['format'] ?? 0],
      exportMode: ExportMode.values[json['exportMode'] ?? 0],
      customOutputPath: json['customOutputPath'],
      width: json['width'] ?? 1920,
      height: json['height'] ?? 1080,
      quality: json['quality'] ?? 0.8,
      lockAspectRatio: json['lockAspectRatio'] ?? true,
      aspectRatio: json['aspectRatio'] ?? (1920 / 1080),
      dimensionLock: DimensionLock.values[json['dimensionLock'] ?? 0],
      language: json['language'] ?? 'zh',
      fontSizeFactor: json['fontSizeFactor'] ?? 1.0,
    );
  }

  ProcessingSettings copyWith({
    ImageFormat? format,
    ExportMode? exportMode,
    String? customOutputPath,
    int? width,
    int? height,
    double? quality,
    bool? lockAspectRatio,
    double? aspectRatio,
    DimensionLock? dimensionLock,
    String? language,
    double? fontSizeFactor,
  }) {
    return ProcessingSettings(
      format: format ?? this.format,
      exportMode: exportMode ?? this.exportMode,
      customOutputPath: customOutputPath ?? this.customOutputPath,
      width: width ?? this.width,
      height: height ?? this.height,
      quality: quality ?? this.quality,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      dimensionLock: dimensionLock ?? this.dimensionLock,
      language: language ?? this.language,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
    );
  }
}

class SettingsNotifier extends Notifier<ProcessingSettings> {
  static const _key = 'oku_settings';
  
  @override
  ProcessingSettings build() {
    // 初始同步返回默认值，随后触发异步加载
    _loadSettings();
    return ProcessingSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr);
        state = ProcessingSettings.fromJson(map);
      } catch (e) {
        // 解码失败则保持默认
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.toJson());
    await prefs.setString(_key, jsonStr);
  }

  void updateState(ProcessingSettings newState) {
    state = newState;
    _saveSettings();
  }

  void setFormat(ImageFormat format) => updateState(state.copyWith(format: format));
  void setExportMode(ExportMode mode) => updateState(state.copyWith(exportMode: mode));
  void setCustomOutputPath(String? path) => updateState(state.copyWith(customOutputPath: path));
  void setLanguage(String lang) => updateState(state.copyWith(language: lang));
  void setFontSizeFactor(double factor) => updateState(state.copyWith(fontSizeFactor: factor));

  void setDimensionLock(DimensionLock lock) {
    updateState(state.copyWith(dimensionLock: lock));
  }

  void setWidth(int width) {
    if (state.dimensionLock == DimensionLock.height) return;
    
    if (state.lockAspectRatio && width > 0) {
      final newHeight = (width / state.aspectRatio).round();
      updateState(state.copyWith(width: width, height: newHeight));
    } else {
      final newRatio = (width > 0 && state.height > 0) ? width / state.height : state.aspectRatio;
      updateState(state.copyWith(width: width, aspectRatio: newRatio));
    }
  }

  void setHeight(int height) {
    if (state.dimensionLock == DimensionLock.width) return;
    
    if (state.lockAspectRatio && height > 0) {
      final newWidth = (height * state.aspectRatio).round();
      updateState(state.copyWith(height: height, width: newWidth));
    } else {
      final newRatio = (state.width > 0 && height > 0) ? state.width / height : state.aspectRatio;
      updateState(state.copyWith(height: height, aspectRatio: newRatio));
    }
  }

  void setQuality(double quality) => updateState(state.copyWith(quality: quality));

  void toggleAspectRatioLock() {
    final isLocking = !state.lockAspectRatio;
    if (isLocking && state.width > 0 && state.height > 0) {
      updateState(state.copyWith(
        lockAspectRatio: true,
        aspectRatio: state.width / state.height,
      ));
    } else {
      updateState(state.copyWith(lockAspectRatio: false));
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, ProcessingSettings>(SettingsNotifier.new);
