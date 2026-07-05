import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency.dart';
import '../../core/formatting.dart';

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class CategoryPieChart extends ConsumerWidget {
  const CategoryPieChart({super.key, required this.slices});

  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    if (slices.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sin gastos este mes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final total = slices.fold<double>(0, (sum, s) => sum + s.amount);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: slices.map((s) {
                final pct = total == 0 ? 0 : (s.amount / total * 100);
                return PieChartSectionData(
                  value: s.amount,
                  color: s.color,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: slices.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} · ${formatCurrency(s.amount, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
