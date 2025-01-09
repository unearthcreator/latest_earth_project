import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

// For generating a unique ID
import 'package:uuid/uuid.dart';

// Hypothetical repository/model imports (adjust paths as needed)
import 'package:map_mvp_project/repositories/local_worlds_repository.dart';
import 'package:map_mvp_project/models/world_config.dart';

class EarthCreatorPage extends StatefulWidget {
  /// The carousel card index this "new world" is associated with.
  final int carouselIndex;

  const EarthCreatorPage({
    Key? key,
    required this.carouselIndex,
  }) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  /// Whether the user wants a satellite map vs. standard map.
  bool _isSatellite = false;

  /// Whether we auto-adjust the time bracket (dawn/day/dusk/night) by local time.
  /// Now defaults to false, so user chooses manually by default.
  bool _adjustAfterTime = false;

  /// Manual choice of theme bracket if [_adjustAfterTime] == false.
  String _selectedTheme = 'Day'; // "Dawn", "Day", "Dusk", "Night"

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

  /// Simple bracket logic: 4-7 => Dawn, 7-17 => Day, 17-20 => Dusk, else Night
  String _determineTimeBracket() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 7) return 'Dawn';
    if (hour >= 7 && hour < 17) return 'Day';
    if (hour >= 17 && hour < 20) return 'Dusk';
    return 'Night';
  }

  /// Returns the bracket that should be displayed: 
  /// if user toggled on "auto" => time-based, else the selected dropdown
  String get _currentBracket {
    return _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;
  }

  /// Pick the correct PNG path based on bracket & whether it's satellite.
  String get _themeImagePath {
    final bracket = _currentBracket;
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

  /// Show an alert if the user’s world name is invalid
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

  /// Called when user taps "Save"
  Future<void> _handleSave() async {
    final name = _nameController.text.trim();

    // Validate name length
    if (name.length < 3 || name.length > 20) {
      _showNameErrorDialog();
      return;
    }

    // If auto => bracket = time-based; else bracket = dropdown
    final bracket = _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;

    // "satellite" or "standard"
    final mapType = _isSatellite ? 'satellite' : 'standard';

    // "auto" if _adjustAfterTime == true, else "manual"
    final timeMode = _adjustAfterTime ? 'auto' : 'manual';
    // If manual => store bracket, else null
    final manualTheme = (timeMode == 'manual') ? bracket : null;

    final worldId = const Uuid().v4();
    final newWorldConfig = WorldConfig(
      id: worldId,
      name: name,
      mapType: mapType,
      timeMode: timeMode,
      manualTheme: manualTheme,
      carouselIndex: widget.carouselIndex, // <--- pass the index here
    );

    try {
      await _worldConfigsRepo.addWorldConfig(newWorldConfig);
      logger.i('Saved new WorldConfig with ID=$worldId: $newWorldConfig');
      Navigator.pop(context); // Return to previous screen
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

    // ~40% of screen for preview
    final double previewW = screenWidth * 0.4;
    final double previewH = screenHeight * 0.4;
    // Center it vertically
    final double previewTop = (screenHeight - previewH) / 2;

    // Tweak positions for the toggles + potential dropdown
    const double togglesTop = 60.0;
    const double togglesRight = 16.0;
    const double dropdownTop = togglesTop + 80;
    const double dropdownRight = 16.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // (1) BACK BUTTON top-left
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

            // (2) WORLD NAME (top-center)
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

            // (3) Toggle row for Satellite vs Standard & "adjustAfterTime" (top-right)
            Positioned(
              top: togglesTop,
              right: togglesRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Satellite vs. Standard
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
                  // Our "Choose own style" vs "Style follows time"
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _adjustAfterTime ? 'Style follows time' : 'Choose own style',
                      ),
                      Switch(
                        value: _adjustAfterTime,
                        onChanged: (newVal) {
                          setState(() => _adjustAfterTime = newVal);
                          logger.i(
                            'Adjust after time toggled -> $_adjustAfterTime',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // (4) If user turned OFF time-adjust => show the manual dropdown
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

            // (5) IMAGE PREVIEW (~40% W/H), centered
            Positioned(
              top: previewTop,
              left: (screenWidth - previewW) / 2,
              child: SizedBox(
                width: previewW,
                height: previewH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _themeImagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // (6) SAVE BUTTON bottom-center
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