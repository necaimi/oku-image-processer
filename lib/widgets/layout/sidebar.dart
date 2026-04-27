import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/processing_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/l10n_provider.dart';
import '../../providers/auth_provider.dart';

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
              const Spacer(),
              // --- User Avatar & Custom Menu ---
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: UserAvatarButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserAvatarButton extends ConsumerStatefulWidget {
  const UserAvatarButton({super.key});

  @override
  ConsumerState<UserAvatarButton> createState() => _UserAvatarButtonState();
}

class _UserAvatarButtonState extends ConsumerState<UserAvatarButton> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _hideMenu();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  void _hideMenu() async {
    if (!_isOpen) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final l10n = ref.read(l10nProvider);
    final colors = AppColors.of(context);
    final auth = ref.watch(authProvider);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background listener to close menu when clicking outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideMenu,
            ),
          ),
          Positioned(
            width: 180,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(60, -110), // Positioned relative to avatar
              child: GestureDetector(
                onTap: () {}, // Prevent taps on menu from closing it via background listener
                child: ScaleTransition(
                  scale: _expandAnimation,
                  alignment: Alignment.bottomLeft,
                  child: FadeTransition(
                    opacity: _expandAnimation,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (auth.isLoggedIn) ...[
                              _buildMenuItem(
                                icon: LucideIcons.user,
                                label: l10n.tr('user_profile'),
                                onTap: () {
                                  _hideMenu();
                                  ref.read(navigationProvider.notifier).setView(AppView.profile);
                                },
                              ),
                              const SizedBox(height: 4),
                              Divider(color: colors.border, thickness: 1, height: 1),
                              const SizedBox(height: 4),
                              _buildMenuItem(
                                icon: LucideIcons.log_out,
                                label: l10n.tr('user_logout'),
                                isDanger: true,
                                onTap: () {
                                  _hideMenu();
                                  ref.read(authProvider.notifier).logout();
                                  ref.read(navigationProvider.notifier).setView(AppView.main);
                                },
                              ),
                            ] else ...[
                              _buildMenuItem(
                                icon: LucideIcons.log_in,
                                label: l10n.tr('auth_login'),
                                onTap: () {
                                  _hideMenu();
                                  ref.read(navigationProvider.notifier).setView(AppView.login);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final colors = AppColors.of(context);
    final color = isDanger ? Colors.redAccent : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isOpen ? AppColors.of(context).primary : AppColors.of(context).primary.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isOpen ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).primary.withValues(alpha: 0.3),
                  blurRadius: _isOpen ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'O',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
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
