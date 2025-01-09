import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // <-- for directly inspecting the box
import 'package:map_mvp_project/models/world_config.dart';
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/carousel.dart';
import 'package:map_mvp_project/src/starting_pages/world_selector/widgets/world_selector_buttons.dart';

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

  @override
  void initState() {
    super.initState();
    logger.i('WorldSelectorPage initState -> initializing repo, fetching worlds');
    _worldsRepo = LocalWorldsRepository();

    _fetchAllWorlds();
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

      // 2) Immediately check the box contents to confirm
      const boxName = 'worldConfigsBox'; // same as in LocalWorldsRepository
      final testBox = await Hive.openBox<Map>(boxName);
      logger.i('Box length after clearing: ${testBox.length}');
      for (final key in testBox.keys) {
        logger.i('Remaining key=$key => value=${testBox.get(key)}');
      }
      await testBox.close();

      // 3) Re-fetch to update our UI state
      await _fetchAllWorlds();

      // 4) Optionally show a quick confirmation
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

    // 3) Normal UI path
    try {
      final double screenHeight = MediaQuery.of(context).size.height;
      final double availableHeight = screenHeight - 56 - 40;
      logger.d('Screen height=$screenHeight, availableHeight=$availableHeight');

      return Scaffold(
        body: Column(
          children: [
            // (A) A row of buttons at the top (with “Clear All Worlds”)
            WorldSelectorButtons(
              onClearAll: _handleClearAllWorlds,
            ),

            // (B) The carousel in the remaining space
            Expanded(
              child: Center(
                child: CarouselWidget(
                  availableHeight: availableHeight,
                  // You could pass _worldConfigs here in the future
                  // if you want to reflect actual stored worlds in the carousel
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