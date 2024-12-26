import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/main_menu.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/world_selector.dart';
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

        // A simple named-route map. 
        // '/': MainMenuPage  -> The home/main menu screen
        // '/world_selector': WorldSelectorPage -> Another screen for selecting worlds
        routes: {
          '/': (context) => const MainMenuPage(),
          '/world_selector': (context) => const WorldSelectorPage(),
        },

        // Hides the debug banner in the top-right corner.
        debugShowCheckedModeBanner: false,

        // Sets the current locale from the provider. If null or no matching, defaults are used.
        locale: currentLocale,

        // Localizations delegates: 
        //  1. AppLocalizations.delegate provides your custom localized strings.
        //  2. GlobalMaterialLocalizations, GlobalWidgetsLocalizations, 
        //     and GlobalCupertinoLocalizations are from Flutter for general i18n support.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // The languages you explicitly support in your app.
        supportedLocales: const [
          Locale('en'),
          Locale('sv'),
          // If you want US specifically, you can use Locale('en', 'US') 
          // but be mindful about how you localize 'en' vs. 'en_US' strings.
          Locale('en', 'US'),
        ],
      );
    } catch (e, stackTrace) {
      // STEP 3: If a build error occurs, log it (using your logger from error_handler).
      // Typically, you'd rely on Flutter’s own error handling, but this ensures
      // you capture more logs if needed.
      logger.e('Error while building MyApp widget', error: e, stackTrace: stackTrace);

      // In case of error, return an empty widget, or a fallback UI.
      // This is optional and might hide serious errors from the user, 
      // but helps prevent hard crashes in release builds.
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