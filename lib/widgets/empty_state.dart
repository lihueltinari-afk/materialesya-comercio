import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'my_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final String? botonTexto;
  final VoidCallback? onBoton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.botonTexto,
    this.onBoton,
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
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (botonTexto != null && onBoton != null) ...[
              const SizedBox(height: 24),
              MyButton(
                label: botonTexto!,
                onPressed: onBoton!,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
