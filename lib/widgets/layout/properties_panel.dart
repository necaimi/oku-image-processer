import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/processing_provider.dart';
import '../../providers/l10n_provider.dart';
import '../common/format_chip.dart';
import '../common/input_row.dart';
import '../common/lock_icon_button.dart';

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  Future<void> _pickDirectory(WidgetRef ref) async {
    try {
      String? result = await FilePicker.getDirectoryPath();
      if (result != null) {
        ref.read(settingsProvider.notifier).setCustomOutputPath(result);
      }
    } catch (e) {
      // Handle potential picker errors
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final fileState = ref.watch(fileListProvider);
    final proc = ref.watch(processingProvider);
    final l10n = ref.watch(l10nProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.of(context).background,
        border: Border(left: BorderSide(color: AppColors.of(context).border)),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: proc.isProcessing ? 0.5 : 1.0,
        child: AbsorbPointer(
          absorbing: proc.isProcessing,
          child: Column( // 使用 Column 包裹，确保按钮始终在底部
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('format'),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FormatChip(
                            label: 'JPG',
                            isSelected: settings.format == ImageFormat.jpg,
                            onTap: () => notifier.setFormat(ImageFormat.jpg),
                          ),
                          FormatChip(
                            label: 'PNG',
                            isSelected: settings.format == ImageFormat.png,
                            onTap: () => notifier.setFormat(ImageFormat.png),
                          ),
                          FormatChip(
                            label: 'WEBP',
                            isSelected: settings.format == ImageFormat.webp,
                            onTap: () => notifier.setFormat(ImageFormat.webp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.tr('export_mode'),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FormatChip(
                            label: l10n.tr('new_dir'),
                            isSelected: settings.exportMode == ExportMode.newDirectory,
                            onTap: () => notifier.setExportMode(ExportMode.newDirectory),
                          ),
                          FormatChip(
                            label: l10n.tr('overwrite'),
                            isSelected: settings.exportMode == ExportMode.overwrite,
                            onTap: () => notifier.setExportMode(ExportMode.overwrite),
                          ),
                        ],
                      ),
                      if (settings.exportMode == ExportMode.newDirectory) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _pickDirectory(ref),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.of(context).surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.of(context).border),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.folder_open,
                                    size: 14, color: AppColors.of(context).primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    settings.customOutputPath ?? 'Default: ./oku_output',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.of(context).textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(LucideIcons.chevron_right,
                                    size: 12, color: AppColors.of(context).textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Text(
                        l10n.tr('resize'),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                Column(
                                  children: [
                                    InputRow(
                                      label: l10n.tr('width'),
                                      value: settings.width.toString(),
                                      enabled: settings.dimensionLock != DimensionLock.height,
                                      onChanged: (v) =>
                                          notifier.setWidth(int.tryParse(v) ?? 0),
                                    ),
                                    const SizedBox(height: 8),
                                    InputRow(
                                      label: l10n.tr('height'),
                                      value: settings.height.toString(),
                                      enabled: settings.dimensionLock != DimensionLock.width,
                                      onChanged: (v) =>
                                          notifier.setHeight(int.tryParse(v) ?? 0),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 88,
                                  child: IconButton(
                                    onPressed: () => notifier.toggleAspectRatioLock(),
                                    icon: Icon(
                                      settings.lockAspectRatio
                                          ? LucideIcons.lock
                                          : LucideIcons.lock_open,
                                      size: 14,
                                      color: settings.lockAspectRatio
                                          ? AppColors.of(context).primary
                                          : AppColors.of(context).textSecondary,
                                    ),
                                    tooltip: l10n.tr('tip_lock_ratio'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              LockIconButton(
                                isSelected: settings.dimensionLock == DimensionLock.width,
                                onTap: () => notifier.setDimensionLock(
                                  settings.dimensionLock == DimensionLock.width
                                      ? DimensionLock.none
                                      : DimensionLock.width,
                                ),
                                tooltip: l10n.tr('tip_lock_width'),
                              ),
                              const SizedBox(height: 8),
                              LockIconButton(
                                isSelected: settings.dimensionLock == DimensionLock.height,
                                onTap: () => notifier.setDimensionLock(
                                  settings.dimensionLock == DimensionLock.height
                                      ? DimensionLock.none
                                      : DimensionLock.height,
                                ),
                                tooltip: l10n.tr('tip_lock_height'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.tr('quality'),
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                          ),
                          Text(
                            '${(settings.quality * 100).toInt()}%',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: AppColors.of(context).primary),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.of(context).primary,
                          inactiveTrackColor: AppColors.of(context).surface,
                          thumbColor: AppColors.of(context).primary,
                          overlayColor: AppColors.of(context).glow,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: settings.quality,
                          onChanged: (v) => notifier.setQuality(v),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // --- Watermark Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.tr('watermark'),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                          ),
                          Switch(
                            value: settings.enableWatermark,
                            onChanged: (v) => notifier.setEnableWatermark(v),
                            activeColor: AppColors.of(context).primary,
                          ),
                        ],
                      ),
                      if (settings.enableWatermark) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FormatChip(
                              label: l10n.tr('wm_text'),
                              isSelected: settings.watermarkType == WatermarkType.text,
                              onTap: () => notifier.setWatermarkType(WatermarkType.text),
                            ),
                            FormatChip(
                              label: l10n.tr('wm_image'),
                              isSelected: settings.watermarkType == WatermarkType.image,
                              onTap: () => notifier.setWatermarkType(WatermarkType.image),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (settings.watermarkType == WatermarkType.text)
                          InputRow(
                            label: l10n.tr('wm_content'),
                            value: settings.watermarkText,
                            onChanged: (v) => notifier.setWatermarkText(v),
                          )
                        else
                          GestureDetector(
                            onTap: () async {
                              final result = await FilePicker.pickFiles(
                                type: FileType.image,
                              );
                              if (result != null) {
                                notifier.setWatermarkImagePath(result.files.single.path);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.of(context).border),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.image, size: 14, color: AppColors.of(context).primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      settings.watermarkImagePath != null 
                                          ? p.basename(settings.watermarkImagePath!) 
                                          : l10n.tr('wm_pick_img'),
                                      style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- 3x3 Position Grid ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('wm_pos'),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 84,
                                  height: 84,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.of(context).surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.of(context).border),
                                  ),
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 2,
                                    crossAxisSpacing: 2,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: WatermarkPosition.values.where((p) => p != WatermarkPosition.tile).map((pos) {
                                      final isSelected = settings.watermarkPosition == pos;
                                      return GestureDetector(
                                        onTap: () => notifier.setWatermarkPosition(pos),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.of(context).primary : Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          alignment: Alignment.center,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : AppColors.of(context).textSecondary.withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // --- Tile Toggle & Spacing ---
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tr('theme_mode').contains('外观') ? '平铺模式' : 'TILE MODE', // Simplified tile label
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => notifier.setWatermarkPosition(
                                      settings.watermarkPosition == WatermarkPosition.tile 
                                        ? WatermarkPosition.bottomRight 
                                        : WatermarkPosition.tile
                                    ),
                                    child: Container(
                                      height: 40,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: settings.watermarkPosition == WatermarkPosition.tile ? AppColors.of(context).primary : AppColors.of(context).surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: settings.watermarkPosition == WatermarkPosition.tile ? AppColors.of(context).primary : AppColors.of(context).border),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.layout_grid,
                                            size: 16,
                                            color: settings.watermarkPosition == WatermarkPosition.tile ? Colors.white : AppColors.of(context).textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.tr('wm_enable').contains('启用') ? '全屏平铺' : 'Tile',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: settings.watermarkPosition == WatermarkPosition.tile ? Colors.white : AppColors.of(context).textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (settings.watermarkPosition == WatermarkPosition.tile) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.tr('wm_spacing'),
                                          style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                                        ),
                                        Text('${(settings.watermarkSpacing * 100).toInt()}%', style: TextStyle(fontSize: 12, color: AppColors.of(context).primary)),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      ),
                                      child: Slider(
                                        value: settings.watermarkSpacing,
                                        min: 0.1,
                                        max: 3.0,
                                        onChanged: (v) => notifier.setWatermarkSpacing(v),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.tr('wm_opacity'),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary),
                            ),
                            Text('${(settings.watermarkOpacity * 100).toInt()}%', style: TextStyle(fontSize: 12, color: AppColors.of(context).primary)),
                          ],
                        ),
                        Slider(
                          value: settings.watermarkOpacity,
                          onChanged: (v) => notifier.setWatermarkOpacity(v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              settings.watermarkType == WatermarkType.image ? l10n.tr('wm_scale') : l10n.tr('wm_size'),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12, color: AppColors.of(context).textSecondary),
                            ),
                            Text(
                              settings.watermarkType == WatermarkType.image 
                                  ? '${(settings.watermarkScale * 100).toInt()}%'
                                  : '${settings.watermarkFontSize}px', 
                              style: TextStyle(fontSize: 12, color: AppColors.of(context).primary),
                            ),
                          ],
                        ),
                        if (settings.watermarkType == WatermarkType.image)
                          Slider(
                            value: settings.watermarkScale,
                            min: 0.05,
                            max: 0.5,
                            onChanged: (v) => notifier.setWatermarkScale(v),
                          )
                        else
                          Slider(
                            value: settings.watermarkFontSize.toDouble(),
                            min: 12,
                            max: 200,
                            onChanged: (v) => notifier.setWatermarkFontSize(v.toInt()),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              // 固定在底部的按钮
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: proc.isProcessing || fileState.files.isEmpty
                          ? [Colors.grey.shade800, Colors.grey.shade900]
                          : [AppColors.of(context).primary, const Color(0xFF0055FF)],
                    ),
                    boxShadow: proc.isProcessing || fileState.files.isEmpty
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.of(context).glow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: proc.isProcessing || fileState.files.isEmpty
                        ? null
                        : () => ref
                            .read(processingProvider.notifier)
                            .startBatch(fileState.files, settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      proc.isProcessing ? l10n.tr('processing') : l10n.tr('start_proc'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
