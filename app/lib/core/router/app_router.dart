import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_obieraki/data/repositories/opinie_repository.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';
import 'package:mini_obieraki/features/dodaj_przedmiot/cubit/dodaj_przedmiot_cubit.dart';
import 'package:mini_obieraki/features/dodaj_przedmiot/pages/dodaj_przedmiot_page.dart';
import 'package:mini_obieraki/features/opinie/cubit/dodaj_opinie_cubit.dart';
import 'package:mini_obieraki/features/opinie/cubit/status_opinii_cubit.dart';
import 'package:mini_obieraki/features/opinie/pages/dodaj_opinie_page.dart';
import 'package:mini_obieraki/features/opinie/pages/status_opinii_page.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmiot_detail_cubit.dart';
import 'package:mini_obieraki/features/przedmioty/cubit/przedmioty_cubit.dart';
import 'package:mini_obieraki/features/przedmioty/pages/przedmiot_detail_page.dart';
import 'package:mini_obieraki/features/przedmioty/pages/przedmioty_page.dart';

class AppRouter {
  late final GoRouter config;

  AppRouter() {
    config = GoRouter(
      initialLocation: '/przedmioty',
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, _) => '/przedmioty',
        ),
        GoRoute(
          path: '/przedmioty',
          pageBuilder: (context, state) => _fade(
            state,
            BlocProvider(
              create: (ctx) =>
                  PrzedmiotyCubit(ctx.read<PrzedmiotyRepository>())..load(),
              child: const PrzedmiotyPage(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'dodaj',
              pageBuilder: (context, state) => _slide(
                state,
                BlocProvider(
                  create: (ctx) =>
                      DodajPrzedmiotCubit(ctx.read<PrzedmiotyRepository>()),
                  child: const DodajPrzedmiotPage(),
                ),
              ),
            ),
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id']!;
                return _slide(
                  state,
                  BlocProvider(
                    create: (ctx) => PrzedmiotDetailCubit(
                      ctx.read<PrzedmiotyRepository>(),
                    )..load(id),
                    child: PrzedmiotDetailPage(przedmiotId: id),
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: 'dodaj-opinie',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return _slide(
                      state,
                      BlocProvider(
                        create: (ctx) => DodajOpinieCubit(
                          ctx.read<OpinieRepository>(),
                          id,
                        ),
                        child: DodajOpiniePage(przedmiotId: id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/moja-opinia/:identifier',
          pageBuilder: (context, state) {
            final identifier = state.pathParameters['identifier']!;
            return _slide(
              state,
              BlocProvider(
                create: (ctx) => StatusOpiniiCubit(
                  ctx.read<OpinieRepository>(),
                )..load(identifier),
                child: StatusOpiniiPage(identifier: identifier),
              ),
            );
          },
        ),
      ],
    );
  }

  Page<void> _fade(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      ),
    );
  }

  Page<void> _slide(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  void dispose() => config.dispose();
}
