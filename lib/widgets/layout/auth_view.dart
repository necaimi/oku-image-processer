import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/l10n_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';

enum AuthTab { login, register }

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  AuthTab _activeTab = AuthTab.login;
  bool _useWechat = true; // Default to WeChat login

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 360,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- App Logo/Icon ---
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(LucideIcons.image, color: colors.primary, size: 32),
                    ),
                    const SizedBox(height: 24),
                    
                    // --- Tabs ---
                    Row(
                      children: [
                        _buildTab(l10n.tr('auth_login'), AuthTab.login),
                        _buildTab(l10n.tr('auth_register'), AuthTab.register),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // --- Content Area ---
                    if (_useWechat) 
                      _buildWechatSection(l10n)
                    else 
                      _buildEmailSection(l10n),
                    
                    const SizedBox(height: 32),
                    
                    // --- Switch Method ---
                    TextButton(
                      onPressed: () => setState(() => _useWechat = !_useWechat),
                      child: Text(
                        _useWechat ? l10n.tr('auth_email') : l10n.tr('auth_wechat'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // --- Back to Main ---
              TextButton.icon(
                onPressed: () => ref.read(navigationProvider.notifier).setView(AppView.main),
                icon: const Icon(LucideIcons.arrow_left, size: 16),
                label: Text(l10n.tr('nav_main')),
                style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, AuthTab tab) {
    final colors = AppColors.of(context);
    final isSelected = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.textPrimary : colors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWechatSection(L10n l10n) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mock QR Code
              Icon(LucideIcons.qr_code, size: 140, color: Colors.grey.shade300),
              // Mock Brand Overlay (using image icon as placeholder for wechat)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Icon(LucideIcons.message_circle, color: Color(0xFF07C160), size: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tr('auth_qr_hint'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tr('auth_qr_expire'),
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmailSection(L10n l10n) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: l10n.tr('auth_email_hint'),
            prefixIcon: const Icon(LucideIcons.mail, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: l10n.tr('auth_password_hint'),
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_activeTab == AuthTab.register) ...[
          const SizedBox(height: 16),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: l10n.tr('auth_password_hint').contains('密码') ? '请再次输入密码' : 'Confirm your password',
              prefixIcon: const Icon(LucideIcons.shield_check, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
        if (_activeTab == AuthTab.login) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(l10n.tr('auth_forgot'), style: const TextStyle(fontSize: 12)),
            ),
          ),
        ] else
          const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: () {
            // Mock Login/Register
            ref.read(authProvider.notifier).login('Oku User', 'user@oku.io');
            ref.read(navigationProvider.notifier).setView(AppView.main);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            _activeTab == AuthTab.login ? l10n.tr('auth_login') : l10n.tr('auth_register'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
