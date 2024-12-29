import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  // Dawn, Day, Dusk, Night. Default to "Day"
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

    // For sizing the “mini‐globe” at 40% of screen dimensions:
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double globeWidth = screenWidth * 0.4;   // 40% of width
    final double globeHeight = screenHeight * 0.4; // 40% of height

    return Scaffold(
      // No AppBar; we'll place all elements manually in a Stack.
      body: SafeArea(
        child: Stack(
          children: [

            /// (A) BACK BUTTON – top left
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

            /// (B) THEME DROPDOWN – top right
            Positioned(
              top: 16,
              right: 16,
              child: Row(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// (C) WORLD NAME TEXTFIELD – top center
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              // Align to top center horizontally
              child: Center(
                child: SizedBox(
                  width: screenWidth * 0.25, // 25% of screen width
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'World Name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),

            /// (D) MINI-GLOBE CONTAINER – truly centered
            Center(
              child: Container(
                width: globeWidth,
                height: globeHeight,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Globe Preview\n(40% of screen)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),

            /// (E) SAVE BUTTON – bottom center
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    logger.i(
                      'Save tapped. '
                      '(Name: ${_nameController.text}, Theme: $_selectedTheme)',
                    );
                    // Future: persist Earth config, then pop or navigate
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