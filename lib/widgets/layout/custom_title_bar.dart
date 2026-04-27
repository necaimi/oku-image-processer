import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../theme.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});
@override
Widget build(BuildContext context) {
  final colors = AppColors.of(context);
  final buttonColors = WindowButtonColors(
    iconNormal: colors.textSecondary,
    mouseOver: colors.surface,
    mouseDown: colors.primary,
    iconMouseOver: colors.textPrimary,
    iconMouseDown: colors.textPrimary,
  );

  final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: colors.textSecondary,
    iconMouseOver: Colors.white,
  );

  return Container(
    height: 32,
    decoration: BoxDecoration(
      color: colors.background,
      border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
    ),
    child: WindowTitleBarBox(
      child: Row(
        children: [
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/oku_logo.png',
            width: 18,
            height: 18,
          ),
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
