import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/main_menu.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/world_selector.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/options/options.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart'; // <-- Import EarthCreatorPage
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
      // STEP 1: Watch the currentLocale from the Riverpod provider.
      // This allows reactive locale updates: if the user changes the language,
      // Flutter rebuilds with the new locale.
      final currentLocale = ref.watch(localeProvider);

      // STEP 2: Build the MaterialApp and return it.
      return MaterialApp(
        // Title displayed in app switchers, app name, etc.
        title: 'Map MVP Project',

        // Provide a theme to the entire app; see `_buildAppTheme()` for details.
        theme: _buildAppTheme(),

        // The initial route is '/', which leads to MainMenuPage in the `routes` map.
        initialRoute: '/',

        // A simple named-route map:
        //   '/':               -> MainMenuPage (the main/home menu)
        //   '/world_selector': -> WorldSelectorPage (carousel of worlds)
        //   '/options':        -> OptionsPage (localization & volume controls)
        //   '/earth_creator':  -> EarthCreatorPage (create/edit new Earth scenarios)
        routes: {
          '/': (context) => const MainMenuPage(),
          '/world_selector': (context) => const WorldSelectorPage(),
          '/options': (context) => const OptionsPage(),
          '/earth_creator': (context) => const EarthCreatorPage(), // <-- NEW ROUTE
        },

        // Hides the debug banner in the top-right corner.
        debugShowCheckedModeBanner: false,

        // Sets the current locale from the provider. 
        // If null or unsupported, it falls back to your default configuration.
        locale: currentLocale,

        // Localizations delegates:
        //  1. AppLocalizations.delegate for your custom strings
        //  2. GlobalMaterialLocalizations, etc., for Flutter’s built-in i18n
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Supported locales in your app
        supportedLocales: const [
          Locale('en'),
          Locale('sv'),
          Locale('en', 'US'),
        ],
      );
    } catch (e, stackTrace) {
      // STEP 3: If a build error occurs, log it.
      logger.e('Error while building MyApp widget', error: e, stackTrace: stackTrace);

      // Return a fallback UI on error.
      return const SizedBox();
    }
  }

  /// Constructs the base ThemeData for your app.
  /// If your theming becomes large or you need multiple themes (e.g., dark mode),
  /// consider breaking this out into a separate file.
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      // Additional styling (fonts, brightness, etc.) can go here.
    );
  }
}