import 'package:flutter/material.dart';
// We'll prefix import to avoid collisions with Flutter's own `Visibility` widget
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as MB;

import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';

class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  // Dawn, Day, Dusk, Night
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

    // We'll make the "globe" ~40% of the screen in both width and height.
    final double globeW = screenWidth * 0.4;
    final double globeH = screenHeight * 0.4;

    // Vertical offset for the globe so it's roughly centered.
    final double globeTop = (screenHeight - globeH) / 2;

    // Pinned the theme dropdown at the right, aligned with the globe’s center.
    final double themeVerticalCenter = globeTop + (globeH / 2) - 15;

    // Example camera options for the “preview” globe
    final MB.CameraOptions cameraOptionsForPreview = MB.CameraOptions(
      center: MB.Point(coordinates: MB.Position(0.0, 0.0)),
      zoom: 0.0,
      bearing: 0.0,
      pitch: 0.0,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // (1) BACK BUTTON (top-left)
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

            // (3) MAPBOX GLOBE PREVIEW (~40% W/H), centered
            Positioned(
              top: globeTop,
              left: (screenWidth - globeW) / 2,
              child: SizedBox(
                width: globeW,
                height: globeH,
                child: MB.MapWidget(
                  styleUri: MapConfig.styleUriGlobe,
                  cameraOptions: cameraOptionsForPreview,

                  /// We'll disable the scale bar and hide the sky 
                  /// once the map is created & style is fully loaded.
                  onMapCreated: (MB.MapboxMap mapboxMap) async {
                    logger.i('EarthCreator: Map created for default globe preview.');

                    // 1) Disable the scale bar ornament
                    await mapboxMap.scaleBar.updateSettings(
                      MB.ScaleBarSettings(enabled: false),
                      
                    );

                      try {
                        final style = mapboxMap.style;
                        // Retrieve the existing layer named "sky"
                        final layer = await style.getLayer("sky");
                        if (layer is MB.SkyLayer) {
                          // Set `visibility = NONE`
                          layer.visibility = MB.Visibility.NONE;
                          // Update that layer in the style
                          await style.updateLayer(layer);
                          logger.i('Successfully hid the sky layer (fully transparent).');
                        } else {
                          logger.w('No "sky" layer found or not a SkyLayer.');
                        }
                      } catch (e) {
                        logger.e('Error hiding sky layer: $e');
                      }
              
                  },
                ),
              ),
            ),

            // (4) THEME pinned on the right, aligned with the globe’s vertical center
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
                  const SizedBox(width: 8),
                  const Text(
                    'Theme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // (5) SAVE BUTTON bottom-center
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