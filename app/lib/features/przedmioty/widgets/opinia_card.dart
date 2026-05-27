import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/opinia.dart';
import 'package:mini_obieraki/shared/widgets/star_display.dart';
import 'package:mini_obieraki/shared/widgets/trudnosc_chip.dart';

class OpiniaCard extends StatelessWidget {
  final Opinia opinia;

  const OpiniaCard({super.key, required this.opinia});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarDisplay(rating: opinia.ocena.toDouble(), size: 16),
              const Gap(8),
              TrudnoscChip(poziom: opinia.trudnosc),
              const Spacer(),
              if (opinia.zmoderowanaAutomatycznie)
                _AutoModerationBadge(),
              if (opinia.dataOpublikowania != null) ...[
                const Gap(8),
                Text(
                  _formatDate(opinia.dataOpublikowania!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const Gap(10),
          Text(
            opinia.tresc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'sty', 'lut', 'mar', 'kwi', 'maj', 'cze',
      'lip', 'sie', 'wrz', 'paź', 'lis', 'gru',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _AutoModerationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Treść została zmodyfikowana automatycznie przez moderatora AI',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.pendingColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.pendingColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high_rounded,
                size: 12, color: AppTheme.pendingColor),
            const Gap(4),
            Text(
              'zmodyfikowano AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.pendingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
