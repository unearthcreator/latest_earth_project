import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

// For generating a unique ID
import 'package:uuid/uuid.dart';

// Hypothetical repository/model imports (adjust paths as needed)
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/models/world_config.dart';

class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  /// Whether we auto-adjust the time bracket (dawn/day/dusk/night) by local time.
  bool _adjustAfterTime = true;

  /// Whether the user wants Satellite map vs. Standard map.
  bool _isSatellite = false;

  /// Manual choice of theme bracket if [_adjustAfterTime] == false.
  String _selectedTheme = 'Day'; // "Dawn", "Day", "Dusk", or "Night"

  // A repository to store newly created worlds in Hive
  late LocalWorldsRepository _worldConfigsRepo;

  @override
  void initState() {
    super.initState();
    logger.i('EarthCreatorPage initState');
    _worldConfigsRepo = LocalWorldsRepository();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Determine a bracket (Dawn/Day/Dusk/Night) based on local time.
  String _determineTimeBracket() {
    final now = DateTime.now();
    final hour = now.hour;

    // Simple example intervals:
    // Dawn: 4–7, Day: 7–17, Dusk: 17–20, Night: 20–4
    if (hour >= 4 && hour < 7) return 'Dawn';
    if (hour >= 7 && hour < 17) return 'Day';
    if (hour >= 17 && hour < 20) return 'Dusk';
    return 'Night';
  }

  /// Based on the user’s toggles, compute the correct image asset path.
  String get _themeImagePath {
    // 1) Figure out the final bracket (auto vs. manual)
    final bracket = _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;

    // 2) If satellite is chosen, prefix "Satellite-"
    if (_isSatellite) {
      switch (bracket) {
        case 'Dawn':
          return 'assets/earth_snapshot/Satellite-Dawn.png';
        case 'Dusk':
          return 'assets/earth_snapshot/Satellite-Dusk.png';
        case 'Night':
          return 'assets/earth_snapshot/Satellite-Night.png';
        case 'Day':
        default:
          return 'assets/earth_snapshot/Satellite-Day.png';
      }
    } else {
      // Standard map
      switch (bracket) {
        case 'Dawn':
          return 'assets/earth_snapshot/Dawn.png';
        case 'Dusk':
          return 'assets/earth_snapshot/Dusk.png';
        case 'Night':
          return 'assets/earth_snapshot/Night.png';
        case 'Day':
        default:
          return 'assets/earth_snapshot/Day.png';
      }
    }
  }

  /// Show an alert dialog if the user’s world name is invalid
  void _showNameErrorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invalid Title'),
          content: const Text('World Name must be between 3 and 20 characters.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Handle the Save button:
  ///  1) Validate name length
  ///  2) Construct & store a WorldConfig
  ///  3) Pop the page if successful
  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    // 1) Validate name
    if (name.length < 3 || name.length > 20) {
      _showNameErrorDialog();
      return;
    }

    // 2) Determine which bracket is actually used
    final bracket = _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;

    // 3) Determine map type
    final mapType = _isSatellite ? 'satellite' : 'standard';

    // 4) timeMode: "auto" if adjustAfterTime==true, else "manual"
    final timeMode = _adjustAfterTime ? 'auto' : 'manual';

    // 5) If timeMode == 'manual', store bracket in manualTheme; else null
    final manualTheme = (timeMode == 'manual') ? bracket : null;

    // 6) Build the WorldConfig object
    final worldId = const Uuid().v4();
    final newWorldConfig = WorldConfig(
      id: worldId,
      name: name,
      mapType: mapType,
      timeMode: timeMode,
      manualTheme: manualTheme,
    );

    // 7) Save to Hive
    try {
      await _worldConfigsRepo.addWorldConfig(newWorldConfig);
      logger.i('Saved new WorldConfig with ID=$worldId: $newWorldConfig');
      Navigator.pop(context); // Return to the previous screen
    } catch (e, stackTrace) {
      logger.e('Error saving new WorldConfig', error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: failed to save world config')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ~40% of screen for the preview
    final double previewW = screenWidth * 0.4;
    final double previewH = screenHeight * 0.4;
    final double previewTop = (screenHeight - previewH) / 2;

    // We'll pin toggles near the top-right
    const double togglesTop = 60.0;
    const double togglesRight = 16.0;

    // If manual dropdown is needed, place it somewhat below the toggles
    const double dropdownTop = togglesTop + 80;
    const double dropdownRight = 16.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // (A) BACK BUTTON top-left
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                  logger.i('User tapped back button on EarthCreatorPage');
                },
              ),
            ),

            // (B) WORLD NAME top-center
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: screenWidth * 0.3,
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'World Name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),

            // (C) Toggle row (top-right) for Satellite/Standard, and "Adjust by Time"
            Positioned(
              top: togglesTop,
              right: togglesRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Satellite vs. Standard, with toggled label
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_isSatellite ? 'Satellite' : 'Standard'),
                      Switch(
                        value: _isSatellite,
                        onChanged: (newVal) {
                          setState(() => _isSatellite = newVal);
                          logger.i(
                            'Map type toggled -> ${_isSatellite ? "Satellite" : "Standard"}',
                          );
                        },
                      ),
                    ],
                  ),
                  // Adjust by time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Adjust by Time'),
                      Switch(
                        value: _adjustAfterTime,
                        onChanged: (newVal) {
                          setState(() => _adjustAfterTime = newVal);
                          logger.i('Adjust after time toggled -> $_adjustAfterTime');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // (D) If user turned off _adjustAfterTime, show the manual dropdown
            if (!_adjustAfterTime)
              Positioned(
                top: dropdownTop,
                right: dropdownRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: _selectedTheme,
                      items: const [
                        DropdownMenuItem(value: 'Dawn', child: Text('Dawn')),
                        DropdownMenuItem(value: 'Day',  child: Text('Day')),
                        DropdownMenuItem(value: 'Dusk', child: Text('Dusk')),
                        DropdownMenuItem(value: 'Night',child: Text('Night')),
                      ],
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedTheme = newValue);
                          logger.i('User selected theme: $newValue');
                        }
                      },
                    ),
                  ],
                ),
              ),

            // (E) IMAGE PREVIEW (~40% W/H), centered
            Positioned(
              top: previewTop,
              left: (screenWidth - previewW) / 2,
              child: SizedBox(
                width: previewW,
                height: previewH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _themeImagePath, // <--- Show actual image from logic above
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // (F) SAVE BUTTON bottom-center
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}