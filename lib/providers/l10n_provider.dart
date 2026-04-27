import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class L10n {
  static const Map<String, Map<String, String>> _data = {
    'zh': {
      'format': '输出格式',
      'export_mode': '导出模式',
      'new_dir': '新目录',
      'overwrite': '覆盖原图',
      'resize': '尺寸调整',
      'width': '宽度',
      'height': '高度',
      'quality': '质量',
      'start_proc': '开始处理',
      'processing': '处理中...',
      'done': '处理完成',
      'clear_all': '清空列表',
      'items_selected': '已选择项',
      'drag_hint': '拖拽图片或文件夹到此处',
      'support_hint': '支持 PNG, JPG, WEBP',
      'searching': '搜索资源中...',
      'scanning': '正在扫描文件夹',
      'init_engine': '启动引擎',
      'handshake': '建立连接',
      'pause': '暂停',
      'resume': '恢复',
      'cancel': '取消',
      'history': '任务历史',
      'settings': '软件设置',
      'language': '语言',
      'font_size': '字体大小',
      'theme_mode': '外观界面',
      'theme_light': '浅色主题',
      'theme_dark': '深色主题',
      'theme_system': '跟随系统',
      'no_history': '暂无历史记录',
      'processed_count': '处理了 {} 张图片',
      'confirm_clear_title': '确认清空？',
      'confirm_clear_content': '这将从队列中移除所有已选图片。',
      'confirm_clear_btn': '清空',
      'cancel_btn': '取消',
      'tip_lock_ratio': '锁定宽高比',
      'tip_lock_width': '锁定宽度为目标',
      'tip_lock_height': '锁定高度为目标',
      'nav_main': '主工作区',
      'nav_history': '历史任务',
      'nav_settings': '设置',
      'watermark': '水印设置',
      'wm_enable': '启用水印',
      'wm_type': '类型',
      'wm_text': '文本',
      'wm_image': '图片',
      'wm_content': '水印内容',
      'wm_opacity': '不透明度',
      'wm_scale': '缩放比例',
      'wm_size': '字体大小',
      'wm_pos': '位置',
      'wm_spacing': '平铺间距',
      'wm_pick_img': '选择水印图',
    },
    'en': {
      'format': 'FORMAT',
      'export_mode': 'EXPORT MODE',
      'new_dir': 'NEW DIR',
      'overwrite': 'OVERWRITE',
      'resize': 'RESIZE',
      'width': 'Width',
      'height': 'Height',
      'quality': 'QUALITY',
      'start_proc': 'Start Processing',
      'processing': 'Processing...',
      'done': 'Done',
      'clear_all': 'Clear All',
      'items_selected': 'ITEMS SELECTED',
      'drag_hint': 'Drag images or folders here',
      'support_hint': 'Supports PNG, JPG, WEBP',
      'searching': 'SEARCHING RESOURCES...',
      'scanning': 'Scanning folders for images',
      'init_engine': 'Launching engine',
      'handshake': 'Handshaking',
      'pause': 'Pause',
      'resume': 'Resume',
      'cancel': 'Cancel',
      'history': 'TASK HISTORY',
      'settings': 'SETTINGS',
      'language': 'Language',
      'font_size': 'Font Size',
      'theme_mode': 'APPEARANCE',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'System',
      'no_history': 'No history yet',
      'processed_count': 'Processed {} images',
      'confirm_clear_title': 'Clear All Items?',
      'confirm_clear_content': 'This will remove all selected images from the queue.',
      'confirm_clear_btn': 'Clear',
      'cancel_btn': 'Cancel',
      'tip_lock_ratio': 'Lock Aspect Ratio',
      'tip_lock_width': 'Lock Width as Target',
      'tip_lock_height': 'Lock Height as Target',
      'nav_main': 'Main Workspace',
      'nav_history': 'Task History',
      'nav_settings': 'Settings',
      'watermark': 'WATERMARK',
      'wm_enable': 'Enable Watermark',
      'wm_type': 'Type',
      'wm_text': 'Text',
      'wm_image': 'Image',
      'wm_content': 'Content',
      'wm_opacity': 'Opacity',
      'wm_scale': 'Scale',
      'wm_size': 'Font Size',
      'wm_pos': 'Position',
      'wm_spacing': 'Spacing',
      'wm_pick_img': 'Select Image',
    }
  };

  final String lang;
  L10n(this.lang);

  String tr(String key, [List<String>? args]) {
    String text = _data[lang]?[key] ?? key;
    if (args != null) {
      for (var arg in args) {
        text = text.replaceFirst('{}', arg);
      }
    }
    return text;
  }
}

final l10nProvider = Provider((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.language));
  return L10n(lang);
});
