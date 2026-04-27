import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/l10n_provider.dart';
import '../common/format_chip.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

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
