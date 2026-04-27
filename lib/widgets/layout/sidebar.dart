import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/processing_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/l10n_provider.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(processingProvider.select((s) => s.isProcessing));
    final currentView = ref.watch(navigationProvider);
    final l10n = ref.watch(l10nProvider);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.of(context).background,
        border: Border(right: BorderSide(color: AppColors.of(context).border, width: 1)),
      ),
      child: IgnorePointer(
        ignoring: isProcessing,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isProcessing ? 0.4 : 1.0,
          child: Column(
            children: [
              const SizedBox(height: 24),
              _SidebarIcon(
                icon: LucideIcons.layout_grid, 
                isSelected: currentView == AppView.main,
                tooltip: l10n.tr('nav_main'),
                onTap: () => ref.read(navigationProvider.notifier).setView(AppView.main),
              ),
              _SidebarIcon(
                icon: LucideIcons.history, 
                isSelected: currentView == AppView.history,
                tooltip: l10n.tr('nav_history'),
                onTap: () => ref.read(navigationProvider.notifier).setView(AppView.history),
              ),
              _SidebarIcon(
                icon: LucideIcons.settings, 
                isSelected: currentView == AppView.settings,
                tooltip: l10n.tr('nav_settings'),
                onTap: () => ref.read(navigationProvider.notifier).setView(AppView.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final String tooltip;
  final VoidCallback onTap;
  
  const _SidebarIcon({
    required this.icon, 
    required this.onTap,
    required this.tooltip,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        margin: const EdgeInsets.only(left: 72),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Icon(
            icon,
            color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
