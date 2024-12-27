import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart'; // Make sure lottie is in pubspec.yaml
import 'package:map_mvp_project/services/error_handler.dart'; // For logging
import 'package:map_mvp_project/l10n/app_localizations.dart'; // For localized strings
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';

/// MainMenuPage acts as the primary entry screen for your application.
/// It displays a full-screen Lottie animation in the background (a spinning Earth),
/// and places navigational buttons on top. These buttons lead to various parts
/// of the app, such as the World Selector, Options, etc.
class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Log that the MainMenuPage build method has started, and get localized strings.
    logger.i('Building MainMenuPage');
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      // You can keep the backgroundColor if desired, but if you want the Lottie 
      // to be fully visible, you can omit or set this to Colors.transparent.
      // backgroundColor: Colors.blueGrey[900],

      // 2) Using a Stack to place the Lottie animation behind the menu.
      body: Stack(
        children: [
          // (A) Lottie background animation, filling the screen.
          Positioned.fill(
            child: Lottie.asset(
              // Use your JSON file path here:
              'assets/animations/lottie/spinning_earth_animation.json',
              fit: BoxFit.cover, // Stretches/crops to fill entire background
              // Optional callbacks to log info or warnings:
              onLoaded: (composition) {
                logger.i(
                  'Lottie loaded successfully! '
                  'Frames: ${composition.startFrame}–${composition.endFrame}, '
                  'Duration: ${composition.duration}',
                );
              },
              onWarning: (warning) {
                logger.w('Lottie warning: $warning');
              },
            ),
          ),

          // (B) The menu itself, centered on top of the background animation.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Only as tall as needed
              children: [
                // Button 1: World Selector
                MenuButton(
                  icon: Icons.public,
                  label: loc.goToWorlds, // e.g. "Go To Worlds"
                  onPressed: () {
                    logger.i('Navigating to World Selector Page');
                    Navigator.pushNamed(context, '/world_selector');
                  },
                ),
                const SizedBox(height: 20),

                // Button 2: Options
                MenuButton(
                  icon: Icons.settings,
                  label: loc.options, // e.g. "Options"
                  onPressed: () {
                    logger.i('Options button clicked');
                    Navigator.pushNamed(context, '/options');
                  },
                ),
                const SizedBox(height: 20),

                // Button 3: Subscription
                MenuButton(
                  icon: Icons.star,
                  label: loc.subscription, // e.g. "Subscription"
                  onPressed: () {
                    logger.i('Subscription button clicked');
                    // Future: subscription logic
                  },
                ),
                const SizedBox(height: 20),

                // Button 4: Exit
                MenuButton(
                  icon: Icons.exit_to_app,
                  label: loc.exit, // e.g. "Exit"
                  onPressed: () {
                    logger.i('Exit button clicked');
                    // Future: exit logic (e.g., confirm before closing)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}