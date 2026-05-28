import 'package:flutter/material.dart';
import 'package:mini_obieraki/core/router/app_router.dart';
import 'package:mini_obieraki/core/theme/app_theme.dart';

class MiniObierkiApp extends StatefulWidget {
  const MiniObierkiApp({super.key});

  @override
  State<MiniObierkiApp> createState() => _MiniObierkiAppState();
}

class _MiniObierkiAppState extends State<MiniObierkiApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MiNI Obieraki',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _appRouter.config,
    );
  }
}
