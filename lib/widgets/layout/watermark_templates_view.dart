import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../theme.dart';
import '../../providers/watermark_template_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/l10n_provider.dart';
import '../common/format_chip.dart';
import '../common/input_row.dart';

class WatermarkTemplatesView extends ConsumerStatefulWidget {
  const WatermarkTemplatesView({super.key});

  @override
  ConsumerState<WatermarkTemplatesView> createState() => _WatermarkTemplatesViewState();
}

class _WatermarkTemplatesViewState extends ConsumerState<WatermarkTemplatesView> {
  String? _editingId;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(WatermarkTemplate template) {
    setState(() {
      _editingId = template.id;
      _nameController.text = template.name;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingId = null;
    });
  }

  void _addNew(WidgetRef ref, L10n l10n) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newTemplate = WatermarkTemplate(id: id, name: l10n.tr('wm_new_template'));
    ref.read(watermarkTemplatesProvider.notifier).add(newTemplate);
    _startEditing(newTemplate);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WatermarkTemplate template, L10n l10n) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(l10n.tr('wm_delete_confirm_title')),
        content: Text(l10n.tr('wm_delete_confirm_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.tr('cancel_btn'), style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.tr('confirm_clear_btn'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(watermarkTemplatesProvider.notifier).remove(template.id);
      _cancelEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(watermarkTemplatesProvider);
    final l10n = ref.watch(l10nProvider);
    final colors = AppColors.of(context);

    return Container(
      color: colors.background,
      child: Row(
        children: [
          // Left: Template List
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: colors.border)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.tr('nav_watermark'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _addNew(ref, l10n),
                        icon: const Icon(LucideIcons.plus, size: 20),
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: templates.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final t = templates[index];
                      final isSelected = _editingId == t.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _startEditing(t),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary.withValues(alpha: 0.1) : colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? colors.primary : colors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  t.type == WatermarkType.text ? LucideIcons.type : LucideIcons.image,
                                  size: 16,
                                  color: isSelected ? colors.primary : colors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? colors.primary : colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(LucideIcons.chevron_right, size: 14, color: colors.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: Editor
          Expanded(
            child: _editingId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.stamp, size: 64, color: colors.border),
                        const SizedBox(height: 16),
                        Text(
                          l10n.tr('wm_template_hint'),
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _buildEditor(templates.firstWhere((t) => t.id == _editingId)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(WatermarkTemplate template) {
    final l10n = ref.watch(l10nProvider);
    final colors = AppColors.of(context);
    final notifier = ref.read(watermarkTemplatesProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (v) => notifier.update(template.copyWith(name: v)),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.tr('wm_template_name'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref, template, l10n),
                icon: const Icon(LucideIcons.trash_2, size: 16),
                label: Text(l10n.tr('wm_delete')),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
          const Divider(height: 48),
          
          // --- Watermark Type ---
          Text(
            l10n.tr('wm_type'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FormatChip(
                label: l10n.tr('wm_text'),
                isSelected: template.type == WatermarkType.text,
                onTap: () => notifier.update(template.copyWith(type: WatermarkType.text)),
              ),
              FormatChip(
                label: l10n.tr('wm_image'),
                isSelected: template.type == WatermarkType.image,
                onTap: () => notifier.update(template.copyWith(type: WatermarkType.image)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- Content ---
          if (template.type == WatermarkType.text)
            InputRow(
              label: l10n.tr('wm_content'),
              value: template.text,
              onChanged: (v) => notifier.update(template.copyWith(text: v)),
            )
          else
            GestureDetector(
              onTap: () async {
                final result = await FilePicker.pickFiles(type: FileType.image);
                if (result != null) {
                  notifier.update(template.copyWith(imagePath: result.files.single.path));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.image, size: 20, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        template.imagePath != null ? p.basename(template.imagePath!) : l10n.tr('wm_pick_img'),
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    const Icon(LucideIcons.upload, size: 16),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),

          // --- Position & Opacity ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position Grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('wm_pos'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: WatermarkPosition.values.where((p) => p != WatermarkPosition.tile).map((pos) {
                        final isSelected = template.position == pos;
                        return GestureDetector(
                          onTap: () => notifier.update(template.copyWith(position: pos)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : colors.textSecondary.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
              // Sliders
              Expanded(
                child: Column(
                  children: [
                    _buildSliderRow(
                      label: l10n.tr('wm_opacity'),
                      value: template.opacity,
                      onChanged: (v) => notifier.update(template.copyWith(opacity: v)),
                    ),
                    const SizedBox(height: 24),
                    if (template.type == WatermarkType.image)
                      _buildSliderRow(
                        label: l10n.tr('wm_scale'),
                        value: template.scale,
                        min: 0.05,
                        max: 0.5,
                        onChanged: (v) => notifier.update(template.copyWith(scale: v)),
                        displayValue: '${(template.scale * 100).toInt()}%',
                      )
                    else
                      _buildSliderRow(
                        label: l10n.tr('wm_size'),
                        value: template.fontSize.toDouble(),
                        min: 12,
                        max: 200,
                        onChanged: (v) => notifier.update(template.copyWith(fontSize: v.toInt())),
                        displayValue: '${template.fontSize}px',
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // --- Tile Mode ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.layout_grid, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.tr('wm_tile_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: template.position == WatermarkPosition.tile,
                      onChanged: (v) => notifier.update(template.copyWith(
                        position: v ? WatermarkPosition.tile : WatermarkPosition.bottomRight,
                      )),
                      activeThumbColor: colors.primary,
                    ),
                  ],
                ),
                if (template.position == WatermarkPosition.tile) ...[
                  const SizedBox(height: 16),
                  _buildSliderRow(
                    label: l10n.tr('wm_spacing'),
                    value: template.spacing,
                    min: 0.1,
                    max: 3.0,
                    onChanged: (v) => notifier.update(template.copyWith(spacing: v)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
    String? displayValue,
  }) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            Text(
              displayValue ?? '${(value * 100).toInt()}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: colors.primary,
        ),
      ],
    );
  }
}
