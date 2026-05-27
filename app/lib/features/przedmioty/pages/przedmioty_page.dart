import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/core/constants/app_constants.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmioty_cubit.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmioty_state.dart';
import 'package:mini_obieraki/features/przedmioty/widgets/przedmiot_card.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';
import 'package:mini_obieraki/shared/widgets/empty_state.dart';
import 'package:mini_obieraki/shared/widgets/error_view.dart';
import 'package:mini_obieraki/shared/widgets/shimmer_card.dart';

class PrzedmiotyPage extends StatefulWidget {
  const PrzedmiotyPage({super.key});

  @override
  State<PrzedmiotyPage> createState() => _PrzedmiotyPageState();
}

class _PrzedmiotyPageState extends State<PrzedmiotyPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => context.read<PrzedmiotyCubit>().search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: ContentWrapper(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(theme),
                  const Gap(24),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: ContentWrapper(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MiNI Obieraki',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Oceny przedmiotów obieralnych',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/przedmioty/dodaj'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Dodaj przedmiot'),
                  ),
                ],
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Szukaj po nazwie, kodzie lub prowadzącym…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: BlocBuilder<PrzedmiotyCubit, PrzedmiotyState>(
          builder: (context, state) {
            if (state is PrzedmiotyLoaded && state.query.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<PrzedmiotyCubit>().search('');
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<PrzedmiotyCubit, PrzedmiotyState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state) {
            PrzedmiotyLoading() => const ShimmerList(count: 6),
            PrzedmiotyLoaded(:final filtered, :final query, :final all, :final sort, :final ascending) =>
              filtered.isEmpty
                  ? EmptyState(
                      icon: query.isEmpty
                          ? Icons.school_outlined
                          : Icons.search_off_rounded,
                      title: query.isEmpty
                          ? 'Brak przedmiotów'
                          : 'Brak wyników dla „$query"',
                      subtitle: query.isEmpty
                          ? 'Dodaj pierwszy przedmiot używając przycisku powyżej.'
                          : 'Spróbuj wyszukać inną frazę.',
                    )
                  : _PrzedmiotyList(
                      items: filtered,
                      totalCount: all.length,
                      query: query,
                      sort: sort,
                      ascending: ascending,
                    ),
            PrzedmiotyFailure(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<PrzedmiotyCubit>().load(),
              ),
            _ => const ShimmerList(count: 6),
          },
        );
      },
    );
  }
}

class _PrzedmiotyList extends StatelessWidget {
  final List items;
  final int totalCount;
  final String query;
  final PrzedmiotySort sort;
  final bool ascending;

  const _PrzedmiotyList({
    required this.items,
    required this.totalCount,
    required this.query,
    required this.sort,
    required this.ascending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              query.isEmpty
                  ? '$totalCount przedmiotów'
                  : '${items.length} z $totalCount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            _SortButton(sort: sort),
            const Gap(6),
            _KierunekButton(sort: sort, ascending: ascending),
          ],
        ),
        const Gap(12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => const Gap(10),
          itemBuilder: (_, i) => PrzedmiotCard(przedmiot: items[i]),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final PrzedmiotySort sort;

  const _SortButton({required this.sort});

  Future<void> _showMenu(BuildContext context) async {
    final theme = Theme.of(context);
    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(0, box.size.height + 4), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<PrzedmiotySort>(
      context: context,
      position: position,
      items: PrzedmiotySort.values.map((s) {
        final isCurrent = s == sort;
        return PopupMenuItem(
          value: s,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.label,
                  style: TextStyle(
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isCurrent)
                Icon(Icons.check_rounded,
                    size: 18, color: theme.colorScheme.primary),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && context.mounted) {
      context.read<PrzedmiotyCubit>().setSort(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded,
                  size: 16, color: theme.colorScheme.primary),
              const Gap(6),
              Text(
                'Sortuj: ${sort.label}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KierunekButton extends StatelessWidget {
  final PrzedmiotySort sort;
  final bool ascending;

  const _KierunekButton({required this.sort, required this.ascending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: ascending ? 'Sortuj rosnąco' : 'Sortuj malejąco',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<PrzedmiotyCubit>().toggleKierunek(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const Gap(4),
              Text(
                ascending ? 'Rosnąco' : 'Malejąco',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
