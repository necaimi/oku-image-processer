import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../../providers/history_provider.dart';
import '../../providers/l10n_provider.dart';

class HistoryListView extends ConsumerWidget {
  const HistoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final l10n = ref.watch(l10nProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('history'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(historyProvider.notifier).clear(),
                  child: Text(l10n.tr('clear_all'), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
        ),
        Expanded(
          child: history.isEmpty 
            ? _buildEmptyState(context, l10n)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildHistoryCard(context, item, l10n);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, L10n l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.history, size: 48, color: AppColors.of(context).textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            l10n.tr('no_history'),
            style: TextStyle(color: AppColors.of(context).textSecondary.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item, L10n l10n) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.timestamp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 允许高度自适应
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible( // 防止日期太长挤占右侧空间
                child: Text(
                  dateStr,
                  style: TextStyle(color: AppColors.of(context).primary, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.duration.inSeconds}.${(item.duration.inMilliseconds % 1000) ~/ 100}s',
                  style: TextStyle(color: AppColors.of(context).primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.files, size: 14, color: AppColors.of(context).textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tr('processed_count', [item.count.toString()]),
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 13),
                  softWrap: true, // 允许换行
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.folder_output, size: 14, color: AppColors.of(context).textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.targetDir,
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                  maxLines: 2, // 目录较长时允许显示两行，避免溢出
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
