import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../theme.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: AppColors.textSecondary,
      mouseOver: AppColors.surface,
      mouseDown: AppColors.primary,
      iconMouseOver: AppColors.textPrimary,
      iconMouseDown: AppColors.textPrimary,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: AppColors.textSecondary,
      iconMouseOver: Colors.white,
    );

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: WindowTitleBarBox(
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(LucideIcons.image, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: MoveWindow(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Oku Image Processor",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
            ),
            MinimizeWindowButton(colors: buttonColors),
            MaximizeWindowButton(colors: buttonColors),
            CloseWindowButton(colors: closeButtonColors),
          ],
        ),
      ),
    );
  }
}
