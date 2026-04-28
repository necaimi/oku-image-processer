import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/layout/custom_title_bar.dart';
import '../widgets/layout/sidebar.dart';
import '../widgets/layout/dropzone_area.dart';
import '../widgets/layout/properties_panel.dart';
import '../widgets/layout/history_list_view.dart';
import '../widgets/layout/settings_view.dart';
import '../widgets/layout/profile_view.dart';
import '../widgets/layout/auth_view.dart';
import '../widgets/layout/watermark_templates_view.dart';
import '../providers/history_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(navigationProvider);

    return Scaffold(
      body: WindowBorder(
        color: AppColors.of(context).border,
        width: 1,
        child: Column(
          children: [
            // Top: Integrated TitleBar
            const CustomTitleBar(),
            
            // Bottom: Three-Column Fluid Layout
            Expanded(
              child: Row(
                children: [
                  // Left: Navigation Sidebar
                  const Sidebar(),
                  
                  // Center: Dynamic View Area
                  Expanded(
                    child: ClipRect(
                      child: _buildMainContent(currentView),
                    ),
                  ),
                  
                  // Right: Parameter Properties Panel (Only in main view)
                  if (currentView == AppView.main)
                    const PropertiesPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppView view) {
    switch (view) {
      case AppView.main:
        return const DropzoneArea();
      case AppView.history:
        return const HistoryListView();
      case AppView.watermarkTemplates:
        return const WatermarkTemplatesView();
      case AppView.settings:
        return const SettingsView();
      case AppView.profile:
        return const ProfileView();
      case AppView.login:
        return const AuthView();
    }
  }
}
