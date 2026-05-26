import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';

class RatingDistributionWidget extends StatelessWidget {
  final Map<int, int> rozkladOcen;
  final int totalOpinii;

  const RatingDistributionWidget({
    super.key,
    required this.rozkladOcen,
    required this.totalOpinii,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = rozkladOcen.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = rozkladOcen[star] ?? 0;
        final fraction =
            (maxCount > 0 && totalOpinii > 0) ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(Icons.star_rounded,
                  size: 14, color: AppTheme.ratingColor),
              const Gap(4),
              Text(
                '$star',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Gap(10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraction),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, _) => FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.ratingColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
