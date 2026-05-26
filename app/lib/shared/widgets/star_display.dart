import 'package:flutter/material.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';

class StarDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const StarDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i < rating;
          return Icon(
            half ? Icons.star_half_rounded : Icons.star_rounded,
            size: size,
            color: filled || half
                ? AppTheme.ratingColor
                : Theme.of(context).colorScheme.outlineVariant,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w600,
              color: AppTheme.ratingColor,
            ),
          ),
        ],
      ],
    );
  }
}
