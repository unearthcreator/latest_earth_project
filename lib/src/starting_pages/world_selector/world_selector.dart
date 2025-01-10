import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // For direct Box usage if needed
import 'package:map_mvp_project/models/world_config.dart';
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';
import 'package:map_mvp_project/repositories/local_app_preferences.dart'; // For last-used index
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/widget_utils/card_tap_handler.dart'; // Contains `handleCardTap`

class WorldSelectorPage extends StatefulWidget {
  const WorldSelectorPage({super.key});

  @override
  State<WorldSelectorPage> createState() => _WorldSelectorPageState();
}

class _WorldSelectorPageState extends State<WorldSelectorPage> {
  late LocalWorldsRepository _worldsRepo;

  /// Store fetched worlds here after loading from Hive.
  List<WorldConfig> _worldConfigs = [];

  /// Loading/error-handling flags
  bool _isLoading = false;
  String? _errorMessage;

  /// Default carousel index (middle card)
  int _carouselInitialIndex = 4;

  @override
  void initState() {
    super.initState();
    logger.i('WorldSelectorPage initState -> initializing repo, fetching worlds.');
    _worldsRepo = LocalWorldsRepository();

    // Fetch worlds and preferences
    _fetchAllWorlds();
    _loadLastUsedIndex();
  }

  Future<void> _loadLastUsedIndex() async {
    try {
      final idx = await LocalAppPreferences.getLastUsedCarouselIndex();
      logger.i('Got lastUsedCarouselIndex=$idx from prefs');
      if (mounted) {
        setState(() => _carouselInitialIndex = idx);
      }
    } catch (e) {
      logger.w('Could not read lastUsedCarouselIndex: $e. Using default=4.');
    }
  }

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
      logger.e('Error fetching worlds', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Failed to load worlds: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClearAllWorlds() async {
    try {
      await _worldsRepo.clearAllWorldConfigs();
      logger.i('Cleared all worlds from Hive.');
      await _fetchAllWorlds();

      // Reset stored last-used index to 4
      await LocalAppPreferences.setLastUsedCarouselIndex(4);

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

  /// Handles card tap and passes the callback to the Carousel
  void _handleCardTap(BuildContext context, int index) {
    logger.i('WorldSelectorPage: Tapped card index $index, delegating to handler.');
    handleCardTap(context, index); // Delegates to card_tap_handler.dart
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building WorldSelectorPage widget.');

    // Show spinner if loading
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if any
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

    // Render UI
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 56 - 40;

    return Scaffold(
      body: Column(
        children: [
          // Buttons row at the top
          WorldSelectorButtons(
            onClearAll: _handleClearAllWorlds,
          ),

          // The carousel
          Expanded(
            child: Center(
              child: CarouselWidget(
                key: ValueKey(_carouselInitialIndex),
                availableHeight: availableHeight,
                initialIndex: _carouselInitialIndex,
                worldConfigs: _worldConfigs,
                onCardTapped: _handleCardTap, // Passes _handleCardTap to CarouselWidget
              ),
            ),
          ),
        ],
      ),
    );
  }
}