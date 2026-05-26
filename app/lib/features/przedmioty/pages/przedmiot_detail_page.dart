import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/przedmiot.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmiot_detail_cubit.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmiot_detail_state.dart';
import 'package:mini_obieraki/features/przedmioty/widgets/opinia_card.dart';
import 'package:mini_obieraki/features/przedmioty/widgets/rating_distribution_widget.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';
import 'package:mini_obieraki/shared/widgets/empty_state.dart';
import 'package:mini_obieraki/shared/widgets/error_view.dart';
import 'package:mini_obieraki/shared/widgets/shimmer_card.dart';
import 'package:mini_obieraki/shared/widgets/star_display.dart';

class PrzedmiotDetailPage extends StatelessWidget {
  final String przedmiotId;

  const PrzedmiotDetailPage({super.key, required this.przedmiotId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrzedmiotDetailCubit, PrzedmiotDetailState>(
      builder: (context, state) {
        return Scaffold(
          body: switch (state) {
            PrzedmiotDetailLoading() => _buildLoading(),
            PrzedmiotDetailLoaded(:final details) =>
              _buildLoaded(context, details),
            PrzedmiotDetailFailure(:final message) => ErrorView(
                message: message,
                onRetry: () =>
                    context.read<PrzedmiotDetailCubit>().load(przedmiotId),
              ),
            _ => _buildLoading(),
          },
          floatingActionButton:
              state is PrzedmiotDetailLoaded
                  ? FloatingActionButton.extended(
                      onPressed: () => context
                          .go('/przedmioty/$przedmiotId/dodaj-opinie'),
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text('Dodaj opinię'),
                    )
                  : null,
        );
      },
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const ShimmerCard(height: 160),
              const Gap(16),
              const ShimmerCard(height: 200),
              const Gap(16),
              const ShimmerList(count: 3),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context, PrzedmiotSzczegoly details) {
    final theme = Theme.of(context);
    final p = details.przedmiot;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/przedmioty'),
          ),
          title: Text(p.nazwa, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton.icon(
              onPressed: () =>
                  context.go('/przedmioty/$przedmiotId/aktualizacja'),
              icon: const Icon(Icons.update_rounded, size: 16),
              label: const Text('Zgłoś aktualizację'),
            ),
            const Gap(8),
          ],
        ),
        SliverToBoxAdapter(
          child: ContentWrapper(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, p),
                if (p.opis != null) ...[
                  const Gap(20),
                  _buildSection(
                    context,
                    'Opis',
                    Text(
                      p.opis!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const Gap(20),
                _buildRatingSection(context, details),
                const Gap(20),
                _buildOpinie(context, details),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Przedmiot p) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      p.nazwa,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (p.prowadzacy != null) ...[
                      const Gap(4),
                      Text(
                        p.prowadzacy!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (p.srednia > 0) ...[
                const Gap(16),
                Column(
                  children: [
                    Text(
                      p.srednia.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ratingColor,
                        height: 1,
                      ),
                    ),
                    const Gap(4),
                    StarDisplay(rating: p.srednia, size: 18),
                    const Gap(4),
                    Text(
                      '${p.liczbaOpinii} opinii',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (p.semestr != null) ...[
            const Gap(12),
            Wrap(
              spacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Semestr ${p.semestr}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context, PrzedmiotSzczegoly details) {
    final p = details.przedmiot;

    return _buildSection(
      context,
      'Rozkład ocen',
      p.liczbaOpinii == 0
          ? const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'Brak ocen',
              subtitle: 'Bądź pierwszą osobą, która oceni ten przedmiot.',
            )
          : RatingDistributionWidget(
              rozkladOcen: details.rozkladOcen,
              totalOpinii: p.liczbaOpinii,
            ),
    );
  }

  Widget _buildOpinie(BuildContext context, PrzedmiotSzczegoly details) {
    return _buildSection(
      context,
      'Opinie (${details.opinie.length})',
      details.opinie.isEmpty
          ? EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Brak opinii',
              subtitle: 'Podziel się swoją oceną tego przedmiotu.',
              action: FilledButton.icon(
                onPressed: () =>
                    context.go('/przedmioty/$przedmiotId/dodaj-opinie'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Dodaj pierwszą opinię'),
              ),
            )
          : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: details.opinie.length,
              separatorBuilder: (_, _) => const Gap(10),
              itemBuilder: (_, i) => OpiniaCard(opinia: details.opinie[i]),
            ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        content,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const Gap(4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
