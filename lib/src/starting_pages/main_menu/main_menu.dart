import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart'; // Make sure you have lottie in pubspec.yaml
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';

class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) Basic logging + retrieve localized strings
    logger.i('Building MainMenuPage');
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      // If you want the Lottie background to fill the screen completely,
      // you can omit the backgroundColor or set it to transparent.
      // backgroundColor: Colors.blueGrey[900],

      body: Stack(
        children: [
          // 2) Fullscreen background Lottie animation
          Positioned.fill(
            child: Lottie.asset(
              // Use your JSON file here:
              'assets/animations/lottie/spinning_earth_animation.json',
              fit: BoxFit.cover,
              // Optional: log info about frames/duration/warnings/errors
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

          // 3) Menu content stacked on top of the Lottie background
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep column as small as needed
              children: [
                MenuButton(
                  icon: Icons.public,
                  label: loc.goToWorlds,
                  onPressed: () {
                    logger.i('Navigating to World Selector Page');
                    Navigator.pushNamed(context, '/world_selector');
                  },
                ),
                const SizedBox(height: 20),

                MenuButton(
                  icon: Icons.settings,
                  label: loc.options,
                  onPressed: () {
                    logger.i('Options button clicked');
                    Navigator.pushNamed(context, '/options');
                  },
                ),
                const SizedBox(height: 20),

                MenuButton(
                  icon: Icons.star,
                  label: loc.subscription,
                  onPressed: () {
                    logger.i('Subscription button clicked');
                    // Future: subscription logic
                  },
                ),
                const SizedBox(height: 20),

                MenuButton(
                  icon: Icons.exit_to_app,
                  label: loc.exit,
                  onPressed: () {
                    logger.i('Exit button clicked');
                    // Future: exit logic
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