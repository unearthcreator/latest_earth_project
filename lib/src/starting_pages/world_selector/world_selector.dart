import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // If you want direct box inspection or usage
import 'package:map_mvp_project/models/world_config.dart';
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';

// Hypothetical import for "last used index" preferences
import 'package:map_mvp_project/repositories/local_app_preferences.dart';

import 'package:map_mvp_project/src/starting_pages/world_selector/earth_creator/earth_creator.dart';

class WorldSelectorPage extends StatefulWidget {
  const WorldSelectorPage({super.key});

  @override
  State<WorldSelectorPage> createState() => _WorldSelectorPageState();
}

class _WorldSelectorPageState extends State<WorldSelectorPage> {
  late LocalWorldsRepository _worldsRepo;

  /// We'll store all the fetched worlds here after loading from Hive.
  List<WorldConfig> _worldConfigs = [];

  /// Simple loading/error-handling flags
  bool _isLoading = false;
  String? _errorMessage;

  /// This will be the index we pass to the Carousel as the starting centered card.
  /// Default to 4 if we find no specific info in prefs (or if user has zero worlds).
  int _carouselInitialIndex = 4;

  @override
  void initState() {
    super.initState();
    logger.i('WorldSelectorPage initState -> initialize repo, fetch worlds, load index');

    // 1) Initialize our local repository for storing/fetching worlds.
    _worldsRepo = LocalWorldsRepository();

    // 2) Fetch the worlds from Hive.
    _fetchAllWorlds();

    // 3) Also load the "last used" index from local app prefs (if any).
    _loadLastUsedIndex();
  }

  /// Asynchronously fetches the "last used" index from local app prefs,
  /// storing it in `_carouselInitialIndex` if found, or defaulting to 4 otherwise.
  Future<void> _loadLastUsedIndex() async {
    try {
      final idx = await LocalAppPreferences.getLastUsedCarouselIndex();
      logger.i('Got lastUsedCarouselIndex=$idx from prefs');
      if (mounted) {
        setState(() => _carouselInitialIndex = idx);
      }
    } catch (e) {
      // If reading fails or no value is stored, we keep the default of 4.
      logger.w('Could not read lastUsedCarouselIndex: $e. Using default=4.');
    }
  }

  /// Fetch all stored WorldConfig items from Hive and log them.
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

  /// Called when the user taps "Clear All Worlds."
  Future<void> _handleClearAllWorlds() async {
    try {
      // 1) Clear all worlds from the repository
      await _worldsRepo.clearAllWorldConfigs();
      logger.i('Cleared all worlds from Hive.');

      // 2) Re-fetch to update UI
      await _fetchAllWorlds();

      // 3) Reset the stored "last used index" to 4
      await LocalAppPreferences.setLastUsedCarouselIndex(4);

      // 4) Show a quick confirmation, if still mounted
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

  /// Instead of letting the Carousel directly push EarthCreatorPage, 
  /// we do the navigation here. That way, we can .then(...) re-fetch on return.
  void _handleCardTap(int index) {
    // If user picks card #4 => go to EarthMap
    if (index == 4) {
      logger.i('Navigating to EarthMapPage from card index $index.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => /* your EarthMapPage() */ Container()),
      );
    } else {
      logger.i('Navigating to EarthCreatorPage from card index=$index');
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EarthCreatorPage(carouselIndex: index),
        ),
      ).then((didSave) {
        if (didSave == true) {
          logger.i('User saved a new world -> re-fetch from Hive so the UI updates');
          _fetchAllWorlds();
          // If needed, read lastUsedCarouselIndex again, 
          // or rely on EarthCreator’s code that sets it for us.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building WorldSelectorPage widget');

    // 1) If currently loading, show spinner
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

    // 3) Otherwise, normal UI flow
    try {
      final screenHeight = MediaQuery.of(context).size.height;
      final availableHeight = screenHeight - 56 - 40;
      logger.d('ScreenHeight=$screenHeight, availableHeight=$availableHeight');

      // If user has zero worlds, fallback to 4 (the "middle" card).
      if (_worldConfigs.isEmpty) {
        logger.i('No worlds found => forcing carousel index=4');
        _carouselInitialIndex = 4;
      }

      return Scaffold(
        body: Column(
          children: [
            // (A) Buttons row at the top (with “Clear All Worlds”).
            WorldSelectorButtons(
              onClearAll: _handleClearAllWorlds,
            ),

            // (B) The carousel in the remaining space.
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                  initialIndex: _carouselInitialIndex,
                  worldConfigs: _worldConfigs,

                  // Provide a callback so the carousel can tell 
                  // us "user tapped the centered card #index"
                  onCenteredCardTapped: _handleCardTap,
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