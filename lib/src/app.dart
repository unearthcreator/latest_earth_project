import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:map_mvp_project/src/starting_pages/main_menu/main_menu.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/world_selector.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/options/options.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';
import 'package:map_mvp_project/providers/locale_provider.dart';

/// MyApp acts as the root of your Flutter application.
/// It sets up theming, localization, and navigation (routes).
/// In addition, it integrates with Riverpod (through ConsumerWidget)
/// to watch a localeProvider, enabling dynamic locale changes.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // 1) Watch the currentLocale from the Riverpod provider for dynamic locale updates
      final currentLocale = ref.watch(localeProvider);

      return MaterialApp(
        title: 'Map MVP Project',
        theme: _buildAppTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const MainMenuPage(),
          '/world_selector': (context) => const WorldSelectorPage(),
          '/options': (context) => const OptionsPage(),

          // Instead of a fixed EarthCreatorPage, we handle the arguments here
          '/earth_creator': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is int) {
              // Pass the index to EarthCreatorPage
              return EarthCreatorPage(carouselIndex: args);
            } else {
              // If no valid index was passed, default to 0 or handle gracefully
              return const EarthCreatorPage(carouselIndex: 0);
            }
          },
        },
        debugShowCheckedModeBanner: false,
        locale: currentLocale,

        // Provide your localizations delegates:
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('sv'),
          Locale('en', 'US'),
        ],
      );
    } catch (e, stackTrace) {
      logger.e('Error while building MyApp widget', error: e, stackTrace: stackTrace);
      // Return fallback UI on error
      return const SizedBox();
    }
  }

  /// Base app theme. Expand as needed.
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
    );
  }
}