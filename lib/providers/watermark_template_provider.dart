import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';

class WatermarkTemplate {
  final String id;
  final String name;
  final WatermarkType type;
  final String text;
  final String? imagePath;
  final double opacity;
  final WatermarkPosition position;
  final double scale;
  final int fontSize;
  final double spacing;

  WatermarkTemplate({
    required this.id,
    required this.name,
    this.type = WatermarkType.text,
    this.text = 'Oku Image',
    this.imagePath,
    this.opacity = 0.5,
    this.position = WatermarkPosition.bottomRight,
    this.scale = 0.2,
    this.fontSize = 40,
    this.spacing = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'text': text,
    'imagePath': imagePath,
    'opacity': opacity,
    'position': position.index,
    'scale': scale,
    'fontSize': fontSize,
    'spacing': spacing,
  };

  factory WatermarkTemplate.fromJson(Map<String, dynamic> json) {
    return WatermarkTemplate(
      id: json['id'],
      name: json['name'],
      type: WatermarkType.values[json['type'] ?? 0],
      text: json['text'] ?? '',
      imagePath: json['imagePath'],
      opacity: (json['opacity'] ?? 0.5).toDouble(),
      position: WatermarkPosition.values[json['position'] ?? 8],
      scale: (json['scale'] ?? 0.2).toDouble(),
      fontSize: json['fontSize'] ?? 40,
      spacing: (json['spacing'] ?? 1.0).toDouble(),
    );
  }

  WatermarkTemplate copyWith({
    String? name,
    WatermarkType? type,
    String? text,
    String? imagePath,
    double? opacity,
    WatermarkPosition? position,
    double? scale,
    int? fontSize,
    double? spacing,
  }) {
    return WatermarkTemplate(
      id: this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      fontSize: fontSize ?? this.fontSize,
      spacing: spacing ?? this.spacing,
    );
  }
}

class WatermarkTemplatesNotifier extends Notifier<List<WatermarkTemplate>> {
  static const _key = 'oku_watermark_templates';

  @override
  List<WatermarkTemplate> build() {
    _load();
    return [
      WatermarkTemplate(id: 'default_text', name: '默认文字水印'),
    ];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        state = list.map((e) => WatermarkTemplate.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Load templates failed: $e');
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  void add(WatermarkTemplate template) {
    state = [...state, template];
    _save();
  }

  void update(WatermarkTemplate template) {
    state = [
      for (final t in state)
        if (t.id == template.id) template else t
    ];
    _save();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }
}

final watermarkTemplatesProvider = NotifierProvider<WatermarkTemplatesNotifier, List<WatermarkTemplate>>(WatermarkTemplatesNotifier.new);
