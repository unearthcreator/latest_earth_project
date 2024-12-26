import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';
import 'package:map_mvp_project/providers/locale_provider.dart';

/// MainMenuPage is the app's main entry screen.
/// It displays several "MenuButton" widgets for navigating to different parts
/// of the application (like World Selector, Options, etc.).
/// 
/// It also contains localized text for these buttons and a way for the user
/// to switch locales dynamically using Riverpod (ConsumerWidget).
class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Log that building has started (optional debugging).
    logger.i('MainMenuPage build started');

    // 2) Retrieve localization instance (for strings in the user’s chosen language).
    final loc = AppLocalizations.of(context)!;

    // 3) Example logging: showing what the current locale is, plus a localized string.
    logger.i('Current locale: ${loc.localeName}. goToWorlds="${loc.goToWorlds}"');

    return Scaffold(
      // 4) A dark background color.
      backgroundColor: Colors.blueGrey[900],

      // 5) A Stack so we can position locale-switching buttons at the top,
      //    while centering the main menu in the middle.
      body: Stack(
        children: [
          // 6) Center widget to align the column of menu buttons in the screen’s center.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Minimizes the column’s height
              children: [
                // A custom MenuButton for going to the World Selector page.
                MenuButton(
                  icon: Icons.public,
                  label: loc.goToWorlds, // Localized string "Go To Worlds"
                  onPressed: () {
                    logger.i('Navigating to World Selector Page');
                    Navigator.pushNamed(context, '/world_selector');
                  },
                ),

                const SizedBox(height: 20),

                // Another MenuButton for "Options".
                MenuButton(
                  icon: Icons.settings,
                  label: loc.options,
                  onPressed: () {
                    logger.i('Options button clicked');
                    // Future implementation: Navigate to an Options page, etc.
                  },
                ),

                const SizedBox(height: 20),

                // A MenuButton for "Subscription".
                MenuButton(
                  icon: Icons.star,
                  label: loc.subscription,
                  onPressed: () {
                    logger.i('Subscription button clicked');
                    // Future implementation: e.g., open a subscription page
                  },
                ),

                const SizedBox(height: 20),

                // A MenuButton for "Exit".
                MenuButton(
                  icon: Icons.exit_to_app,
                  label: loc.exit,
                  onPressed: () {
                    logger.i('Exit button clicked');
                    // Future implementation: e.g., close the app or show a confirmation dialog
                  },
                ),
              ],
            ),
          ),

          // 7) Positioned row of buttons at the top-left for changing locale on the fly.
          Positioned(
            top: 40,
            left: 10,
            child: Row(
              children: [
                // Button to set the locale to English (default).
                ElevatedButton(
                  onPressed: () {
                    logger.i('English locale button clicked');
                    ref.read(localeProvider.notifier).state = const Locale('en');
                  },
                  child: const Text('English'),
                ),

                const SizedBox(width: 10),

                // Button to set the locale to Swedish.
                ElevatedButton(
                  onPressed: () {
                    logger.i('Swedish locale button clicked');
                    ref.read(localeProvider.notifier).state = const Locale('sv');
                  },
                  child: const Text('Svenska'),
                ),

                const SizedBox(width: 10),

                // Button to set the locale to English (US).
                ElevatedButton(
                  onPressed: () {
                    logger.i('English (US) locale button clicked');
                    ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                  },
                  child: const Text('English (US)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}