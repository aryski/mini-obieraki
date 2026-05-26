import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/features/dodaj_przedmiot/cubit/dodaj_przedmiot_cubit.dart';
import 'package:mini_obieraki/features/dodaj_przedmiot/cubit/dodaj_przedmiot_state.dart';
import 'package:mini_obieraki/shared/widgets/content_wrapper.dart';

class DodajPrzedmiotPage extends StatefulWidget {
  const DodajPrzedmiotPage({super.key});

  @override
  State<DodajPrzedmiotPage> createState() => _DodajPrzedmiotPageState();
}

class _DodajPrzedmiotPageState extends State<DodajPrzedmiotPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/przedmioty'),
        ),
        title: const Text('Dodaj przedmiot'),
      ),
      body: BlocConsumer<DodajPrzedmiotCubit, DodajPrzedmiotState>(
        listener: (context, state) {
          if (state is DodajPrzedmiotSuccess) {
            context.go('/przedmioty/${state.przedmiot.id}');
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: ContentWrapper(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InstructionCard(),
                    const Gap(24),
                    Text(
                      'Link USOS',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _controller,
                      enabled: state is! DodajPrzedmiotLoading,
                      decoration: const InputDecoration(
                        hintText:
                            'https://usosweb.usos.pw.edu.pl/kontroler.php?...',
                        prefixIcon: Icon(Icons.link_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Wklej link USOS';
                        }
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null ||
                            !uri.host.contains('usos') ||
                            !uri.queryParameters.containsKey('prz_kod')) {
                          return 'Nieprawidłowy link – musi zawierać parametr prz_kod';
                        }
                        return null;
                      },
                      maxLines: 2,
                      minLines: 1,
                    ),
                    if (state is DodajPrzedmiotFailure) ...[
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
                        onPressed: state is DodajPrzedmiotLoading
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  context
                                      .read<DodajPrzedmiotCubit>()
                                      .submit(_controller.text);
                                }
                              },
                        child: state is DodajPrzedmiotLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Dodaj przedmiot'),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'Pobieranie danych z USOS może zająć kilka sekund.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const Gap(8),
              Text(
                'Jak znaleźć link USOS?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Gap(10),
          _Step(
            number: 1,
            text: 'Wejdź na stronę USOS swojej uczelni.',
          ),
          const Gap(6),
          _Step(
            number: 2,
            text:
                'Znajdź przedmiot w Katalogu przedmiotów (sekcja „Studia").',
          ),
          const Gap(6),
          _Step(
            number: 3,
            text:
                'Wejdź na stronę przedmiotu i skopiuj cały adres URL z paska przeglądarki.',
          ),
          const Gap(6),
          _Step(
            number: 4,
            text: 'Wklej link poniżej – resztą zajmie się aplikacja.',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
