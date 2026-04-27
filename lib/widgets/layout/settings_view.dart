import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/l10n_provider.dart';
import '../common/format_chip.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = ref.watch(l10nProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.tr('settings'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              // --- 软件信息 ---
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.hasData ? snapshot.data!.version : '1.0.0';
                  return Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.of(context).border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.of(context).primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.info, color: AppColors.of(context).primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.tr('version')}: v$version',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _launchUrl('https://oku.image.processor'), // 示例官网地址
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.tr('visit_website'),
                                        style: TextStyle(
                                          color: AppColors.of(context).primary,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(LucideIcons.external_link, size: 12, color: AppColors.of(context).primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
              _buildSection(
                context,
                l10n.tr('theme_mode'),
                Row(
                  children: [
                    FormatChip(
                      label: l10n.tr('theme_light'),
                      isSelected: settings.themeMode == ThemeMode.light,
                      onTap: () => notifier.setThemeMode(ThemeMode.light),
                    ),
                    FormatChip(
                      label: l10n.tr('theme_dark'),
                      isSelected: settings.themeMode == ThemeMode.dark,
                      onTap: () => notifier.setThemeMode(ThemeMode.dark),
                    ),
                    FormatChip(
                      label: l10n.tr('theme_system'),
                      isSelected: settings.themeMode == ThemeMode.system,
                      onTap: () => notifier.setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                l10n.tr('language'),
                Row(
                  children: [
                    FormatChip(
                      label: '简体中文',
                      isSelected: settings.language == 'zh',
                      onTap: () => notifier.setLanguage('zh'),
                    ),
                    FormatChip(
                      label: 'English',
                      isSelected: settings.language == 'en',
                      onTap: () => notifier.setLanguage('en'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                '${l10n.tr('font_size')} (${(settings.fontSizeFactor * 100).toInt()}%)',
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.of(context).primary,
                    inactiveTrackColor: AppColors.of(context).surface,
                    thumbColor: AppColors.of(context).primary,
                    overlayColor: AppColors.of(context).glow,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: settings.fontSizeFactor,
                    min: 1.0,
                    max: 1.4,
                    divisions: 4,
                    onChanged: (v) => notifier.setFontSizeFactor(v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}
