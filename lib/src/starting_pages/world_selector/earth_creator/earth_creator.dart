import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

/// A minimal "Earth Creator" page to let the user pick a world name and theme.
/// 
/// Layout specifics:
///  - No AppBar; we use a manual back button top-left that pops the route.
///  - Centered "World Name" text in the TextField (with blinking cursor).
///  - The "Theme" row is near the top-right, 
///    with some margin on the right side of the screen.
///  - "Save" button is placed near the bottom, 
///    mirroring the same vertical spacing as the top.
///  - Now with 4 theme options (Dawn, Day, Dusk, Night), defaulting to "Day".
class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  // Controller for the "World Name" field
  final TextEditingController _nameController = TextEditingController();

  // Basic theme choices: Dawn, Day, Dusk, Night (default to "Day")
  String _selectedTheme = 'Day';

  @override
  void initState() {
    super.initState();
    logger.i('EarthCreatorPage initState: minimal UI setup');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    return Scaffold(
      // No AppBar; we manually place a back button in top-left
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            // Symmetrical top/bottom margin
            const double verticalMargin = 40.0;

            return Stack(
              children: [
                // (A) BACK BUTTON (top-left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // Pop back to the world selector
                      Navigator.pop(context);
                      logger.i('User tapped back button on EarthCreatorPage');
                    },
                  ),
                ),

                // (B) MAIN CONTENT
                SingleChildScrollView(
                  child: Container(
                    height: screenHeight, 
                    padding: EdgeInsets.only(
                      top: verticalMargin,
                      bottom: verticalMargin,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // TOP SECTION
                        Column(
                          children: [
                            // (1) TEXTFIELD "WORLD NAME" in the center
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,            // auto-focus for blinking cursor
                                  textAlign: TextAlign.center, // center the text
                                  decoration: const InputDecoration(
                                    hintText: 'World Name', 
                                    border: UnderlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // (2) THEME CHOICE near the top-right
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Dropdown on the left
                                  DropdownButton<String>(
                                    value: _selectedTheme,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Dawn',
                                        child: Text('Dawn'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Day',
                                        child: Text('Day'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Dusk',
                                        child: Text('Dusk'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Night',
                                        child: Text('Night'),
                                      ),
                                    ],
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() => _selectedTheme = newValue);
                                        logger.i('User selected theme: $newValue');
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // "Theme" label with a small margin on the right
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    child: const Text(
                                      'Theme',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // (C) "SAVE" BUTTON near the bottom
                        ElevatedButton(
                          onPressed: () {
                            logger.i(
                              'Save tapped. '
                              '(Name: ${_nameController.text}, Theme: $_selectedTheme)',
                            );
                            // Future: Actually handle the user’s new Earth config
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Save not yet implemented'),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}