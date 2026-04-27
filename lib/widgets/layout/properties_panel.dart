import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(left: BorderSide(color: AppColors.border)),
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.folder_open,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    settings.customOutputPath ?? 'Default: ./oku_output',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(LucideIcons.chevron_right,
                                    size: 12, color: AppColors.textSecondary),
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
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
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
                            ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surface,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.glow,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: settings.quality,
                          onChanged: (v) => notifier.setQuality(v),
                        ),
                      ),
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
                          : [AppColors.primary, const Color(0xFF0055FF)],
                    ),
                    boxShadow: proc.isProcessing || fileState.files.isEmpty
                        ? null
                        : const [
                            BoxShadow(
                              color: AppColors.glow,
                              blurRadius: 12,
                              offset: Offset(0, 4),
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
