import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // for directly inspecting the box if needed
import 'package:map_mvp_project/models/world_config.dart';
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';

// Hypothetical import for "last used index" preferences
import 'package:map_mvp_project/repositories/local_app_preferences.dart';

class WorldSelectorPage extends StatefulWidget {
  const WorldSelectorPage({super.key});

  @override
  State<WorldSelectorPage> createState() => _WorldSelectorPageState();
}

class _WorldSelectorPageState extends State<WorldSelectorPage> {
  late LocalWorldsRepository _worldsRepo;

  /// We'll store the fetched worlds here after loading from Hive.
  List<WorldConfig> _worldConfigs = [];

  /// Simple loading/error-handling flags
  bool _isLoading = false;
  String? _errorMessage;

  /// This will be the index we pass to the Carousel as the starting centered card.
  /// Default to 4 if we find no specific info in prefs or zero worlds in Hive.
  int _carouselInitialIndex = 4;

  @override
  void initState() {
    super.initState();
    logger.i('WorldSelectorPage initState: setting up repo, fetch worlds, load index');

    // 1) Initialize the local repository for worlds.
    _worldsRepo = LocalWorldsRepository();

    // 2) Fetch the worlds from Hive.
    _fetchAllWorlds();

    // 3) Load the "last used" index from local app prefs (if any).
    _loadLastUsedIndex();
  }

  /// Asynchronously fetch the "last used" index from your local app prefs
  /// and set _carouselInitialIndex accordingly.
  Future<void> _loadLastUsedIndex() async {
    try {
      final idx = await LocalAppPreferences.getLastUsedCarouselIndex();
      logger.i('Got lastUsedCarouselIndex=$idx from prefs');
      if (mounted) {
        setState(() => _carouselInitialIndex = idx);
      }
    } catch (e) {
      // If reading fails or no value was stored, we just keep the default of 4.
      logger.w('Could not read lastUsedCarouselIndex: $e. Using default=4.');
    }
  }

  /// Fetches all stored WorldConfig items from Hive and logs them for debugging.
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

  /// Called when user taps "Clear All Worlds"
  Future<void> _handleClearAllWorlds() async {
    try {
      // 1) Clear all worlds from the repository
      await _worldsRepo.clearAllWorldConfigs();
      logger.i('Cleared all worlds from Hive.');

      // 2) Re-fetch to update our UI state
      await _fetchAllWorlds();

      // 3) Also reset the stored "last used index" to 4
      await LocalAppPreferences.setLastUsedCarouselIndex(4);

      // 4) Show a quick confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All worlds cleared.')),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error clearing worlds', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear all worlds.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building WorldSelectorPage widget');

    // 1) If currently loading, show a spinner
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2) If there was an error, display it
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    // 3) Normal UI logic:
    try {
      final double screenHeight = MediaQuery.of(context).size.height;
      final double availableHeight = screenHeight - 56 - 40;
      logger.d('ScreenHeight=$screenHeight, availableHeight=$availableHeight');

      // If user has zero worlds, fallback to index=4 (the “middle” card).
      if (_worldConfigs.isEmpty) {
        logger.i('No worlds found -> forcing carousel index=4');
        _carouselInitialIndex = 4;
      }

      return Scaffold(
        body: Column(
          children: [
            // (A) A row of buttons at the top (with “Clear All Worlds”).
            WorldSelectorButtons(
              onClearAll: _handleClearAllWorlds,
            ),

            // (B) The carousel in the remaining space
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                  initialIndex: _carouselInitialIndex,
                  worldConfigs: _worldConfigs, // <— pass the stored worlds
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