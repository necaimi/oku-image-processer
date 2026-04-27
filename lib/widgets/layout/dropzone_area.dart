import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/file_provider.dart';
import '../../providers/processing_provider.dart';
import '../../providers/l10n_provider.dart';
import '../common/overlay_button.dart';
import 'file_list_view.dart';

class DropzoneArea extends ConsumerStatefulWidget {
  const DropzoneArea({super.key});

  @override
  ConsumerState<DropzoneArea> createState() => _DropzoneAreaState();
}

class _DropzoneAreaState extends ConsumerState<DropzoneArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(fileListProvider.select((s) => s.isScanning));
    final hasFiles = ref.watch(fileListProvider.select((s) => s.files.isNotEmpty));
    final proc = ref.watch(processingProvider);
    final l10n = ref.watch(l10nProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDragging
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragging ? AppColors.primary : AppColors.border,
          width: 2,
          style: !hasFiles ? BorderStyle.solid : BorderStyle.none,
        ),
        boxShadow: _isDragging
            ? [const BoxShadow(color: AppColors.glow, blurRadius: 20)]
            : null,
      ),
      child: Stack(
        children: [
          // 底层：文件列表与拖拽响应 (处理时禁用)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: proc.isProcessing,
              child: DropTarget(
                onDragDone: (detail) {
                  ref.read(fileListProvider.notifier).addFiles(detail.files);
                },
                onDragEntered: (detail) => setState(() => _isDragging = true),
                onDragExited: (detail) => setState(() => _isDragging = false),
                child: !hasFiles ? _buildEmptyState(l10n) : const FileListView(),
              ),
            ),
          ),
          
          // 扫描中覆盖层
          if (isScanning) _buildScanningOverlay(l10n),
          
          // 处理中覆盖层 (必须在 AbsorbPointer 之外以接收点击)
          if (proc.isProcessing) _buildProcessingOverlay(proc, l10n),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay(L10n l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.tr('searching'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('scanning'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(L10n l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              LucideIcons.plus,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('drag_hint'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('support_hint'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(ProcessingState proc, L10n l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              child: LinearProgressIndicator(
                value: proc.progress > 0 ? proc.progress : null,
                backgroundColor: AppColors.surface,
                color: proc.isPaused ? Colors.orangeAccent : AppColors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              proc.isInitializing 
                ? '${l10n.tr('init_engine')}...' 
                : '[${proc.current}/${proc.total}] ${(proc.progress * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1,
                  color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              proc.isInitializing 
                ? l10n.tr('handshake')
                : (proc.isPaused ? l10n.tr('pause') : l10n.tr('processing')),
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                proc.currentFileName,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!proc.isInitializing) ...[
                  OverlayButton(
                    icon: proc.isPaused ? LucideIcons.play : LucideIcons.pause,
                    label: proc.isPaused ? l10n.tr('resume') : l10n.tr('pause'),
                    color: proc.isPaused ? AppColors.primary : Colors.orangeAccent,
                    onTap: () => ref.read(processingProvider.notifier).togglePause(),
                  ),
                  const SizedBox(width: 16),
                ],
                OverlayButton(
                  icon: LucideIcons.square,
                  label: l10n.tr('cancel'),
                  color: Colors.redAccent,
                  onTap: () => ref.read(processingProvider.notifier).stop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
