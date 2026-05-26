import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';
import 'package:mini_obieraki/shared/widgets/star_display.dart';

class PrzedmiotCard extends StatefulWidget {
  final Przedmiot przedmiot;

  const PrzedmiotCard({super.key, required this.przedmiot});

  @override
  State<PrzedmiotCard> createState() => _PrzedmiotCardState();
}

class _PrzedmiotCardState extends State<PrzedmiotCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.przedmiot;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/przedmioty/${p.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.kod,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (p.semestr != null) ...[
                            const Gap(8),
                            Text(
                              'Sem. ${p.semestr}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(6),
                      Text(
                        p.nazwa,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (p.prowadzacy != null) ...[
                        const Gap(4),
                        Text(
                          p.prowadzacy!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _RatingBadge(srednia: p.srednia),
                    const Gap(6),
                    Text(
                      '${p.liczbaOpinii} opinii',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(4),
                    StarDisplay(rating: p.srednia, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double srednia;

  const _RatingBadge({required this.srednia});

  Color _color() {
    if (srednia >= 4.5) return AppTheme.successColor;
    if (srednia >= 3.5) return AppTheme.ratingColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    if (srednia == 0) {
      return Text(
        'Brak ocen',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        srednia.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _color(),
        ),
      ),
    );
  }
}
