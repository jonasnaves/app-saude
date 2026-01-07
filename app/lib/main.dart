import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AiMeApp(),
    ),
  );
}

class AiMeApp extends StatelessWidget {
  const AiMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AiMe',
      theme: AppTheme.softTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
