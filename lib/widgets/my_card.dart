import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  const MyCard({super.key, required this.child, this.padding, this.onTap, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: onTap != null
          ? InkWell(onTap: onTap, child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child))
          : Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
