import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_obieraki/app.dart';
import 'package:mini_obieraki/data/repositories/opinie_repository.dart';
import 'package:mini_obieraki/data/repositories/przedmioty_repository.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PrzedmiotyRepository>(
          create: (_) => PrzedmiotyRepository(),
        ),
        RepositoryProvider<OpinieRepository>(
          create: (_) => OpinieRepository(),
        ),
      ],
      child: const MiniObierkiApp(),
    ),
  );
}
