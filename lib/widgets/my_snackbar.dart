import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum SnackbarTipo { success, error, info, warning }

class MySnackbar {
  static void mostrar(
    BuildContext context,
    String mensaje, {
    SnackbarTipo tipo = SnackbarTipo.info,
    Duration duracion = const Duration(seconds: 3),
  }) {
    final config = _config(tipo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(config['icono'] as IconData, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: config['color'] as Color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: duracion,
        ),
      );
  }

  static void exito(BuildContext context, String mensaje) =>
      mostrar(context, mensaje, tipo: SnackbarTipo.success);

  static void error(BuildContext context, String mensaje) =>
      mostrar(context, mensaje, tipo: SnackbarTipo.error);

  static void info(BuildContext context, String mensaje) =>
      mostrar(context, mensaje, tipo: SnackbarTipo.info);

  static void advertencia(BuildContext context, String mensaje) =>
      mostrar(context, mensaje, tipo: SnackbarTipo.warning);

  static Map<String, dynamic> _config(SnackbarTipo tipo) {
    switch (tipo) {
      case SnackbarTipo.success:
        return {'color': AppColors.success, 'icono': Icons.check_circle_rounded};
      case SnackbarTipo.error:
        return {'color': AppColors.error, 'icono': Icons.error_rounded};
      case SnackbarTipo.warning:
        return {'color': AppColors.warning, 'icono': Icons.warning_rounded};
      case SnackbarTipo.info:
        return {'color': AppColors.secondary, 'icono': Icons.info_rounded};
    }
  }
}
