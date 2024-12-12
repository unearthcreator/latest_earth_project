import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/main_menu/widgets/menu_button.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';
import 'package:map_mvp_project/providers/locale_provider.dart'; // import the provider

class MainMenuPage extends ConsumerWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  },
                ),
                const SizedBox(height: 20),
                MenuButton(
                  icon: Icons.star,
                  label: loc.subscription,
                  onPressed: () {
                    logger.i('Subscription button clicked');
                  },
                ),
                const SizedBox(height: 20),
                MenuButton(
                  icon: Icons.exit_to_app,
                  label: loc.exit,
                  onPressed: () {
                    logger.i('Exit button clicked');
                  },
                ),
              ],
            ),
          ),

          // Buttons to change locale
          Positioned(
            top: 40,
            left: 10,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Set locale to English
                    ref.read(localeProvider.notifier).state = const Locale('en');
                  },
                  child: const Text('English'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Set locale to Swedish
                    ref.read(localeProvider.notifier).state = const Locale('sv');
                  },
                  child: const Text('Svenska'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}