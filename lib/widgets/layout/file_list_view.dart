import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/file_provider.dart';
import '../../providers/processing_provider.dart';
import '../../providers/l10n_provider.dart';
import '../../providers/settings_provider.dart';

class FileListView extends ConsumerWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileListProvider.select((s) => s.files));
    final isProcessing = ref.watch(processingProvider.select((s) => s.isProcessing));
    final fontSizeFactor = ref.watch(settingsProvider.select((s) => s.fontSizeFactor));
    final l10n = ref.watch(l10nProvider);

    // 动态计算高度：基准 72.0 像素 * 字号缩放系数
    final dynamicExtent = 72.0 * fontSizeFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${files.length} ${l10n.tr('items_selected')}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
              ),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.of(context).surface,
                            title: Text(l10n.tr('confirm_clear_title'),
                                style: TextStyle(color: AppColors.of(context).textPrimary)),
                            content: Text(
                                l10n.tr('confirm_clear_content'),
                                style: TextStyle(color: AppColors.of(context).textSecondary)),
                            actions: [
                              TextButton(
                                child: Text(l10n.tr('cancel_btn'),
                                    style: TextStyle(color: AppColors.of(context).textSecondary)),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: Text(l10n.tr('confirm_clear_btn'),
                                    style: const TextStyle(color: Colors.redAccent)),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(fileListProvider.notifier).clear();
                        }
                      },
                child: Text(
                  l10n.tr('clear_all'),
                  style: TextStyle(
                    color: isProcessing ? Colors.grey : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: files.length,
            // 使用动态计算的高度，完美适配大字号
            itemExtent: dynamicExtent, 
            itemBuilder: (context, index) {
              return FileItem(
                index: index,
                file: files[index],
                isProcessing: isProcessing,
              );
            },
          ),
        ),
      ],
    );
  }
}

class FileItem extends ConsumerWidget {
  final int index;
  final SelectedFile file;
  final bool isProcessing;

  const FileItem({
    super.key,
    required this.index,
    required this.file,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.of(context).background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 40,
                  height: 40,
                  color: AppColors.of(context).surface,
                  child: Icon(
                    LucideIcons.image,
                    size: 20,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isProcessing ? Colors.grey.withValues(alpha: 0.3) : AppColors.of(context).textSecondary,
                ),
                onPressed: isProcessing ? null : () => ref
                    .read(fileListProvider.notifier)
                    .removeFile(index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
