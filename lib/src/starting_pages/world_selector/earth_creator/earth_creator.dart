import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

    // For the Theme dropdown, pinned at right, aligned with the globe's center.
    final double themeVerticalCenter = globeTop + (globeH / 2) - 15;

    // Example camera options for the “preview” globe
    final cameraOptionsForPreview = CameraOptions(
      center: Point(coordinates: Position(0.0, 0.0)),
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
                child: MapWidget(
                  styleUri: MapConfig.styleUriGlobe,
                  cameraOptions: cameraOptionsForPreview,
                  // We'll disable scale bar & remove/transparent the "sky" 
                  // once the style has loaded.
                  onMapCreated: (mapboxMap) async {
                    logger.i('EarthCreator: Map created for default globe preview.');

                    // (A) Hide the scale bar
                    await mapboxMap.scaleBar.updateSettings(
                      ScaleBarSettings(enabled: false),
                    );

                    // (B) Wait for the style to load before removing the sky layer.
                    //     Some plugin versions use subscribeStyleLoaded / onStyleLoaded 
                    //     or onStyleDataLoaded. Adjust if needed:
                    mapboxMap.subscribeStyleLoaded((_) async {
                      logger.i('Style loaded -> removing sky layer for transparency.');
                      try {
                        // Attempt to remove the default "sky" layer
                        await mapboxMap.style.removeLayer("sky");
                        logger.i('Removed sky layer successfully — sky is now transparent.');
                      } catch (err) {
                        // Possibly the layer name is something else, or doesn't exist
                        logger.e('Could not remove sky layer: $err');
                      }
                    });
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
