import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../theme.dart';

class LockIconButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const LockIconButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.of(context).primary.withValues(alpha: 0.1)
                : AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.of(context).primary : AppColors.of(context).border,
            ),
          ),
          child: Icon(
            LucideIcons.target,
            size: 14,
            color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
          ),
        ),
      ),
    );
  }
}
