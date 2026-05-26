import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/features/aktualizacja/cubit/aktualizacja_cubit.dart';
import 'package:mini_obieraki/features/aktualizacja/cubit/aktualizacja_state.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';

class AktualizacjaPage extends StatefulWidget {
  final String przedmiotId;

  const AktualizacjaPage({super.key, required this.przedmiotId});

  @override
  State<AktualizacjaPage> createState() => _AktualizacjaPageState();
}

class _AktualizacjaPageState extends State<AktualizacjaPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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
        title: const Text('Zgłoś aktualizację'),
      ),
      body: BlocBuilder<AktualizacjaCubit, AktualizacjaState>(
        builder: (context, state) {
          if (state is AktualizacjaSuccess) {
            return _buildSuccess(context);
          }

          final isLoading = state is AktualizacjaLoading;

          return SingleChildScrollView(
            child: ContentWrapper(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(),
                  const Gap(24),
                  Text(
                    'Aktualny link USOS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  TextField(
                    controller: _controller,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText:
                          'https://usosweb.usos.pw.edu.pl/kontroler.php?_action=katalog2/...',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                  if (state is AktualizacjaFailure) ...[
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 18, color: theme.colorScheme.error),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              state.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AktualizacjaCubit>()
                              .submit(_controller.text),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Wyślij zgłoszenie'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ContentWrapper(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: Color(0xFF059669),
              ),
            ),
            const Gap(16),
            Text(
              'Zgłoszenie wysłane',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Text(
              'Administrator otrzymał Twoje zgłoszenie i zweryfikuje aktualizację danych.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    context.go('/przedmioty/${widget.przedmiotId}'),
                child: const Text('Wróć do przedmiotu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update_rounded,
                  size: 18, color: theme.colorScheme.tertiary),
              const Gap(8),
              Text(
                'Kiedy warto zgłosić aktualizację?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            'Jeśli dane przedmiotu (np. nazwa, kod, prowadzący) zmieniły się w USOS – wklej aktualny link. Administrator zweryfikuje zmiany i zaktualizuje informacje.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
