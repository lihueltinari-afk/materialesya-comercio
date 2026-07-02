import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

enum MyButtonVariant { primary, secondary, outline, ghost, danger }

class MyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MyButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final double? width;
  final double height;

  const MyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MyButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;
    Color bg, fg, border;
    switch (variant) {
      case MyButtonVariant.primary:
        bg = isDisabled ? AppColors.textLight : AppColors.primary;
        fg = Colors.white;
        border = Colors.transparent;
      case MyButtonVariant.secondary:
        bg = AppColors.secondary;
        fg = Colors.white;
        border = Colors.transparent;
      case MyButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = AppColors.primary;
      case MyButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.textSecondary;
        border = Colors.transparent;
      case MyButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        border = Colors.transparent;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: border != Colors.transparent ? Border.all(color: border, width: 1.5) : null,
              boxShadow: variant == MyButtonVariant.primary && !isDisabled
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), offset: const Offset(0, 4), blurRadius: 12)]
                : null,
            ),
            child: Center(
              child: loading
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, color: fg, size: 18), const SizedBox(width: 8)],
                    Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
