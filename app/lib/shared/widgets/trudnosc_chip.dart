import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/opinia.dart';

/// Wskaźnik poziomu trudności (cecha przedmiotu): Łatwy / Średni / Trudny.
class TrudnoscChip extends StatelessWidget {
  final PoziomTrudnosci poziom;
  final bool compact;

  const TrudnoscChip({super.key, required this.poziom, this.compact = false});

  Color get _color => switch (poziom) {
        PoziomTrudnosci.latwy => AppTheme.successColor,
        PoziomTrudnosci.sredni => AppTheme.ratingColor,
        PoziomTrudnosci.trudny => AppTheme.errorColor,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 11, color: _color),
          const Gap(4),
          Text(
            poziom.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
