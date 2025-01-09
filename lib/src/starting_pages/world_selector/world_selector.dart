import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';

// Hypothetical imports for your local worlds repository & model
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/models/world_config.dart';

/// A page that allows the user to select which "world" (scenario) to enter.
/// It uses a button row at the top (WorldSelectorButtons) and a carousel
/// (CarouselWidget) in the main body to showcase selectable worlds.
class WorldSelectorPage extends StatefulWidget {
  const WorldSelectorPage({super.key});

  @override
  State<WorldSelectorPage> createState() => _WorldSelectorPageState();
}

class _WorldSelectorPageState extends State<WorldSelectorPage> {
  late LocalWorldsRepository _worldsRepo;

  /// We’ll store the fetched worlds here.
  List<WorldConfig> _worldConfigs = [];

  /// Simple loading/error handling flags
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    logger.i('WorldSelectorPage initState -> initializing repo, fetching worlds');
    _worldsRepo = LocalWorldsRepository(); // or however you instantiate

    _fetchAllWorlds();
  }

  /// Fetches all stored WorldConfig items from Hive
  /// and logs them for debugging.
  Future<void> _fetchAllWorlds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final worlds = await _worldsRepo.getAllWorldConfigs();
      logger.i('Fetched worlds from Hive: $worlds');

      setState(() {
        _worldConfigs = worlds;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.e('Error fetching worlds from Hive', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Failed to load worlds: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building WorldSelectorPage widget');

    // 1) If currently loading, show a simple spinner
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2) If there was an error, display it
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    try {
      // 3) If we have worlds (or none), we continue with normal UI

      // Calculate carousel height
      final double screenHeight = MediaQuery.of(context).size.height;
      final double availableHeight = screenHeight - 56 - 40;

      logger.d(
        'Screen height: $screenHeight, Available height for carousel: $availableHeight',
      );

      return Scaffold(
        body: Column(
          children: [
            // A row of buttons at the top
            const WorldSelectorButtons(),

            // The carousel in the remaining space
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                  // In the future, you might pass _worldConfigs here
                  // if you want the carousel to reflect existing worlds:
                  // e.g.  carouselWorlds: _worldConfigs,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Error building WorldSelectorPage', error: e, stackTrace: stackTrace);
      return const Scaffold(
        body: Center(child: Text('Error loading World Selector')),
      );
    }
  }
}