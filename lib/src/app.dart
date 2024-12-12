import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/main_menu.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/world_selector.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';
import 'package:map_mvp_project/providers/locale_provider.dart'; // import the localeProvider

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final currentLocale = ref.watch(localeProvider);

      return MaterialApp(
        title: 'Map MVP Project',
        theme: _buildAppTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const MainMenuPage(),
          '/world_selector': (context) => const WorldSelectorPage(),
        },
        debugShowCheckedModeBanner: false,

        locale: currentLocale, // Read the chosen locale from the provider
        localizationsDelegates: const [
          AppLocalizations.delegate, // Add the generated delegate
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('sv'),
        ],
      );
    } catch (e, stackTrace) {
      logger.e('Error while building MyApp widget', error: e, stackTrace: stackTrace);
      return const SizedBox();
    }
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
    );
  }
}