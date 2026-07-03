import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MyTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icono;
  final Widget? sufijo;
  final bool obscureText;
  final String? errorText;
  final bool? exito;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  const MyTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icono,
    this.sufijo,
    this.obscureText = false,
    this.errorText,
    this.exito,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasSuccess = exito == true && !hasError;

    Color borderColor = AppColors.divider;
    if (hasError) borderColor = AppColors.error;
    if (hasSuccess) borderColor = AppColors.success;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icono != null ? Icon(icono, color: AppColors.textSecondary, size: 20) : null,
        suffixIcon: sufijo,
        errorText: hasError ? errorText : null,
        filled: true,
        fillColor: enabled ? AppColors.surface : const Color(0xFFF3F4F6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: hasSuccess ? 1.5 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? AppColors.error : AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        labelStyle: TextStyle(
          color: hasError ? AppColors.error : AppColors.textSecondary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
