import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

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

  /// Manual choice of theme bracket if _adjustAfterTime == false.
  String _selectedTheme = 'Day'; // options: Dawn, Day, Dusk, Night

  @override
  void initState() {
    super.initState();
    logger.i('EarthCreatorPage initState');
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

  /// Build the image path based on standard vs. satellite and the bracket.
  String get _themeImagePath {
    // 1) Figure out which bracket to use
    final bracket = _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;

    // 2) If satellite is chosen, use "Satellite-Dawn.png" etc.
    //    Otherwise, just "Dawn.png" etc.
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

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ~40% of screen for the preview
    final double previewW = screenWidth * 0.4;
    final double previewH = screenHeight * 0.4;

    // Center it vertically
    final double previewTop = (screenHeight - previewH) / 2;

    // We'll pin toggles near the top-right
    const double togglesTop = 60.0;
    const double togglesRight = 16.0;

    // If manual dropdown is needed, place it somewhat below the toggles.
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

            // (C) Toggle row (top-right) for Satellite vs Standard, and "Adjust by Time"
            Positioned(
              top: togglesTop,
              right: togglesRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Satellite / Standard
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Satellite'),
                      Switch(
                        value: _isSatellite,
                        onChanged: (newVal) {
                          setState(() => _isSatellite = newVal);
                          logger.i('Satellite toggled -> $_isSatellite');
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
                    _themeImagePath,
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
                  onPressed: () {
                    // Final bracket: either from local time or manual dropdown
                    final bracket = _adjustAfterTime ? _determineTimeBracket() : _selectedTheme;
                    final styleType = _isSatellite ? 'Satellite' : 'Standard';

                    logger.i(
                      'Save tapped. '
                      'Name: ${_nameController.text}, '
                      'Bracket: $bracket, Style: $styleType',
                    );

                    // Future: persist or pass this data onward
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save not yet implemented')),
                    );
                  },
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