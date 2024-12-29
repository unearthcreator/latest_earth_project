import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Make sure you have the correct version

class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  // Example themes: Dawn, Day, Dusk, Night
  String _selectedTheme = 'Day';

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

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // We'll make the "globe" ~40% of the screen in both width & height.
    final double globeW = screenWidth * 0.4;
    final double globeH = screenHeight * 0.4;

    // Center the globe vertically:
    final double globeTop = (screenHeight - globeH) / 2;

    // Align the theme dropdown with the globe's vertical center.
    final double themeVerticalCenter = globeTop + (globeH / 2) - 15;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // (1) Back button top-left
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

            // (2) World Name top-center
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

            // (3) Globe preview (~40% W/H), centered
            Positioned(
              top: globeTop,
              left: (screenWidth - globeW) / 2, // horizontally center
              child: SizedBox(
                width: globeW,
                height: globeH,
                child: MapWidget(
                  // Use your “Default Globe” style:
                  styleUri: MapConfig.styleUriGlobe,
                  // Use your default camera config or something similar:
                  cameraOptions: MapConfig.defaultCameraOptions,

                  // If needed: onMapCreated, onStyleLoaded, etc.
                  onMapCreated: (mapboxMap) {
                    logger.i('EarthCreator: Map created for default globe preview.');
                  },
                ),
              ),
            ),

            // (4) Theme pinned on the right, aligned with globe center
            Positioned(
              top: themeVerticalCenter,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedTheme,
                    items: const [
                      DropdownMenuItem(value: 'Dawn', child: Text('Dawn')),
                      DropdownMenuItem(value: 'Day', child: Text('Day')),
                      DropdownMenuItem(value: 'Dusk', child: Text('Dusk')),
                      DropdownMenuItem(value: 'Night', child: Text('Night')),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedTheme = newValue);
                        logger.i('User selected theme: $newValue');
                        // Future: Possibly change style or camera for each theme
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Theme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // (5) Save button bottom-center
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    logger.i(
                      'Save tapped. '
                      '(Name: ${_nameController.text}, Theme: $_selectedTheme)',
                    );
                    // Future: Actually handle the user’s new Earth config
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