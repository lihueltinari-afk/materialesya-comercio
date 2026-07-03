import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'my_button.dart';

class ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const ErrorState({
    super.key,
    this.mensaje = 'Algo salió mal. Verificá tu conexión e intentá de nuevo.',
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin conexión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 24),
              MyButton(
                texto: 'Reintentar',
                onPressed: onReintentar!,
                width: 160,
                icono: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
