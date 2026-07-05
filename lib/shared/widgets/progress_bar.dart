import 'package:flutter/material.dart';

class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });

  /// 0.0 a 1.0+ (valores > 1 se recortan visualmente pero el color cambia
  /// a rojo para indicar exceso).
  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final isOverBudget = progress > 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(isOverBudget ? Colors.red : color),
      ),
    );
  }
}
