import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/opinia.dart';
import 'package:mini_obieraki/features/opinie/cubit/dodaj_opinie_cubit.dart';
import 'package:mini_obieraki/features/opinie/cubit/dodaj_opinie_state.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';

class DodajOpiniePage extends StatefulWidget {
  final String przedmiotId;

  const DodajOpiniePage({super.key, required this.przedmiotId});

  @override
  State<DodajOpiniePage> createState() => _DodajOpiniePageState();
}

class _DodajOpiniePageState extends State<DodajOpiniePage> {
  final _trescController = TextEditingController();
  int _ocena = 4;
  PoziomTrudnosci _trudnosc = PoziomTrudnosci.sredni;
  static const int _maxChars = 1000;
  static const int _minChars = 10;

  @override
  void dispose() {
    _trescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/przedmioty/${widget.przedmiotId}'),
        ),
        title: const Text('Dodaj opinię'),
      ),
      body: BlocConsumer<DodajOpinieCubit, DodajOpinieState>(
        listener: (context, state) {
          if (state is DodajOpinieSuccess) {
            context.go('/moja-opinia/${state.identifier}');
          }
        },
        builder: (context, state) {
          final isLoading = state is DodajOpinieLoading;

          return SingleChildScrollView(
            child: ContentWrapper(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingSection(theme, isLoading),
                  const Gap(24),
                  _buildTrudnoscSection(theme, isLoading),
                  const Gap(24),
                  _buildTrescSection(theme, isLoading),
                  if (state is DodajOpinieFailure) ...[
                    const Gap(12),
                    _ErrorBanner(message: state.message),
                  ],
                  const Gap(24),
                  _buildSubmitSection(context, state, isLoading),
                  const Gap(16),
                  _buildAnonymityNote(theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme, bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twoja ocena',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        AbsorbPointer(
          absorbing: disabled,
          child: RatingBar.builder(
            initialRating: _ocena.toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 40,
            glow: false,
            itemBuilder: (_, _) => const Icon(
              Icons.star_rounded,
              color: AppTheme.ratingColor,
            ),
            unratedColor: Colors.grey.shade300,
            onRatingUpdate: (r) => setState(() => _ocena = r.toInt()),
          ),
        ),
        const Gap(6),
        Text(
          _ratingLabel(_ocena),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.ratingColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static Color _trudnoscColor(PoziomTrudnosci p) => switch (p) {
        PoziomTrudnosci.latwy => AppTheme.successColor,
        PoziomTrudnosci.sredni => AppTheme.ratingColor,
        PoziomTrudnosci.trudny => AppTheme.errorColor,
      };

  Widget _buildTrudnoscSection(ThemeData theme, bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Poziom trudności',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            for (final p in PoziomTrudnosci.values) ...[
              if (p != PoziomTrudnosci.values.first) const Gap(8),
              Expanded(child: _trudnoscOption(theme, p, disabled)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _trudnoscOption(ThemeData theme, PoziomTrudnosci p, bool disabled) {
    final selected = _trudnosc == p;
    final color = _trudnoscColor(p);

    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _trudnosc = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : theme.colorScheme.outline,
              ),
            ),
            const Gap(8),
            Text(
              p.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrescSection(ThemeData theme, bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Opinia',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: _trescController,
              builder: (_, value, _) {
                final count = value.text.length;
                return Text(
                  '$count / $_maxChars',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: count > _maxChars
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
        const Gap(8),
        TextField(
          controller: _trescController,
          enabled: !disabled,
          decoration: const InputDecoration(
            hintText:
                'Co myślisz o tym przedmiocie? Jak wyglądały zajęcia, materiały, zaliczenie?',
          ),
          maxLines: 6,
          minLines: 4,
          maxLength: _maxChars,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null,
        ),
        const Gap(6),
        Text(
          'Oceniaj zajęcia, nie osobę prowadzącego. Minimum $_minChars znaków. '
          'Twoja opinia może zostać zredagowana przez moderatora AI.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection(
      BuildContext context, DodajOpinieState state, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading
            ? null
            : () {
                context.read<DodajOpinieCubit>().submit(
                      ocena: _ocena,
                      trudnosc: _trudnosc,
                      tresc: _trescController.text,
                    );
              },
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Wyślij opinię'),
      ),
    );
  }

  Widget _buildAnonymityNote(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 14, color: theme.colorScheme.onSurfaceVariant),
        const Gap(6),
        Expanded(
          child: Text(
            'Opinie są anonimowe. Nie potrzebujesz konta.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _ratingLabel(int r) {
    return switch (r) {
      1 => 'Bardzo słaby',
      2 => 'Słaby',
      3 => 'Przeciętny',
      4 => 'Dobry',
      5 => 'Świetny',
      _ => '',
    };
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: theme.colorScheme.error),
          const Gap(8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
