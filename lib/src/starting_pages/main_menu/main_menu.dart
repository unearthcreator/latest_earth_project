import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';

/// MainMenuPage is the app's main entry screen.
/// It displays several "MenuButton" widgets for navigating to different parts
/// of the application (like World Selector, Options, etc.).
///
/// It also contains localized text for these buttons.
class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Log that the MainMenuPage build method has started (optional debugging).
    logger.i('MainMenuPage build started');

    // 2) Retrieve the current localized strings for the user’s chosen language.
    final loc = AppLocalizations.of(context)!;

    // 3) Example logging: showing the current locale and a localized string.
    logger.i('Current locale: ${loc.localeName}, goToWorlds="${loc.goToWorlds}"');

    return Scaffold(
      // 4) A dark background color for the main menu.
      backgroundColor: Colors.blueGrey[900],

      // 5) Use a simple Stack or Center to position widgets. Here we only need
      //    a Center because we no longer have top-left positioned locale buttons.
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Minimizes the column’s height
          children: [
            // A custom MenuButton for going to the World Selector page.
            MenuButton(
              icon: Icons.public,
              label: loc.goToWorlds, // Localized "Go to Worlds"
              onPressed: () {
                logger.i('Navigating to World Selector Page');
                Navigator.pushNamed(context, '/world_selector');
              },
            ),
            const SizedBox(height: 20),

            // A MenuButton for "Options".
            MenuButton(
              icon: Icons.settings,
              label: loc.options,
              onPressed: () {
                logger.i('Options button clicked');
                // Navigate to the Options page (assuming you’ve registered '/options' route).
                Navigator.pushNamed(context, '/options');
              },
            ),
            const SizedBox(height: 20),

            // A MenuButton for "Subscription".
            MenuButton(
              icon: Icons.star,
              label: loc.subscription,
              onPressed: () {
                logger.i('Subscription button clicked');
                // Future: open a subscription page or show some subscription-related screen
              },
            ),
            const SizedBox(height: 20),

            // A MenuButton for "Exit" (could confirm before actually closing).
            MenuButton(
              icon: Icons.exit_to_app,
              label: loc.exit,
              onPressed: () {
                logger.i('Exit button clicked');
                // Future: close the app or show a confirmation dialog, etc.
              },
            ),
          ],
        ),
      ),
    );
  }
}