import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';
import 'package:mini_obieraki/data/models/opinia.dart';
import 'package:mini_obieraki/features/opinie/cubit/status_opinii_cubit.dart';
import 'package:mini_obieraki/features/opinie/cubit/status_opinii_state.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';
import 'package:mini_obieraki/shared/widgets/error_view.dart';
import 'package:mini_obieraki/shared/widgets/star_display.dart';
import 'package:mini_obieraki/shared/widgets/trudnosc_chip.dart';

class StatusOpiniiPage extends StatelessWidget {
  final String identifier;

  const StatusOpiniiPage({super.key, required this.identifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/przedmioty'),
        ),
        title: const Text('Status opinii'),
      ),
      body: BlocBuilder<StatusOpiniiCubit, StatusOpiniiState>(
        builder: (context, state) {
          return switch (state) {
            StatusOpiniiLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            StatusOpiniiLoaded(:final opinia) =>
              _buildLoaded(context, opinia),
            StatusOpiniiFailure(:final message) => ErrorView(
                message: message,
                onRetry: () =>
                    context.read<StatusOpiniiCubit>().refresh(identifier),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, Opinia opinia) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: ContentWrapper(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(opinia: opinia),
            const Gap(20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Twoja opinia',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      StarDisplay(
                        rating: opinia.ocena.toDouble(),
                        size: 18,
                        showNumber: true,
                      ),
                      const Gap(8),
                      TrudnoscChip(poziom: opinia.trudnosc),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    opinia.tresc,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            if (opinia.status == StatusOpinii.odrzucona &&
                opinia.powodOdrzucenia != null) ...[
              const Gap(16),
              _RejectionNote(reason: opinia.powodOdrzucenia!),
            ],
            const Gap(24),
            Text(
              'Identyfikator opinii:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(4),
            SelectableText(
              identifier,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(6),
            Text(
              'Zapisz ten identyfikator – pozwoli Ci sprawdzić status opinii w przyszłości.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/przedmioty'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Wróć do listy przedmiotów'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Opinia opinia;

  const _StatusCard({required this.opinia});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, title, subtitle) = _config(opinia.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _config(StatusOpinii status) {
    return switch (status) {
      StatusOpinii.oczekuje => (
          Icons.hourglass_top_rounded,
          AppTheme.pendingColor,
          'Trwa moderacja',
          'Twoja opinia jest sprawdzana przez moderatora AI. Zwykle trwa to kilka minut.',
        ),
      StatusOpinii.opublikowana => (
          Icons.check_circle_rounded,
          AppTheme.successColor,
          'Opinia opublikowana',
          'Twoja opinia jest widoczna na stronie przedmiotu.',
        ),
      StatusOpinii.zmienionaIOpublikowana => (
          Icons.auto_fix_high_rounded,
          AppTheme.pendingColor,
          'Zmodyfikowana i opublikowana',
          'Moderator AI nieznacznie zredagował treść, zachowując sens i ocenę. Opinia jest widoczna publicznie.',
        ),
      StatusOpinii.odrzucona => (
          Icons.cancel_rounded,
          AppTheme.errorColor,
          'Opinia odrzucona',
          'Moderator AI odrzucił opinię. Sprawdź powód poniżej.',
        ),
    };
  }
}

class _RejectionNote extends StatelessWidget {
  final String reason;

  const _RejectionNote({required this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Powód odrzucenia',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.errorColor,
            ),
          ),
          const Gap(6),
          Text(
            reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
