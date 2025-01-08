import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  // Possible theme choices
  String _selectedTheme = 'Day'; // Dawn, Day, Dusk, Night

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

  /// Returns the appropriate image path based on the user’s current theme selection.
  String get _themeImagePath {
    switch (_selectedTheme) {
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

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // We'll make the "preview" ~40% of the screen in both width and height.
    final double previewW = screenWidth * 0.4;
    final double previewH = screenHeight * 0.4;

    // Vertical offset so it’s roughly centered.
    final double previewTop = (screenHeight - previewH) / 2;

    // Position the theme dropdown near the preview’s vertical center.
    final double themeVerticalCenter = previewTop + (previewH / 2) - 15;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // (A) BACK BUTTON (top-left)
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

            // (B) WORLD NAME (top-center)
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

            // (C) THEME pinned on the right, aligned with preview’s vertical center
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

            // (D) IMAGE PREVIEW (~40% W/H), centered
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

            // (E) SAVE BUTTON bottom-center
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