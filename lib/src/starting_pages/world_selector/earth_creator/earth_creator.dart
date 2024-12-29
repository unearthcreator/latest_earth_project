import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

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

    // We'll center the globe by calculating a top offset such that
    // top = (screenHeight - globeH) / 2  (so it's vertically centered).
    final double globeTop = (screenHeight - globeH) / 2;

    // Similarly, if we want the "Theme" dropdown aligned with the globe's vertical center,
    // we can pin it near (globeTop + globeH/2) minus half the dropdown's own height (~15).
    final double themeVerticalCenter = globeTop + (globeH / 2) - 15;

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

            // (2) WORLD NAME top-center
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

            // (3) GLOBE PREVIEW in the absolute center (~40% W/H)
            Positioned(
              top: globeTop,
              left: (screenWidth - globeW) / 2, // horizontally center
              child: Container(
                width: globeW,
                height: globeH,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Globe Preview\n(40% screen size)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // (4) THEME pinned on the right, same vertical center as the globe
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