import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

/// A minimal "Earth Creator" page to let the user pick a world name and theme.
/// Currently does not actually save or persist data—it's just a skeleton.
class EarthCreatorPage extends StatefulWidget {
  const EarthCreatorPage({Key? key}) : super(key: key);

  @override
  State<EarthCreatorPage> createState() => _EarthCreatorPageState();
}

class _EarthCreatorPageState extends State<EarthCreatorPage> {
  // Simple text controller for the "world name"
  final TextEditingController _nameController = TextEditingController();

  // A basic theme choice: just "Light" or "Dark" for now
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    logger.i('EarthCreatorPage initState: setting up minimal UI');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.i('Building EarthCreatorPage');

    // 1) We'll use LayoutBuilder to get the total available width,
    //    so we can set the TextField to 25% of screen width.
    return Scaffold(
      // No AppBar here (removes "Create Earth" title).
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final textFieldWidth = screenWidth * 0.25;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 2) Top-centered label "World Name"
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'World Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3) TextField at 25% of screen width, below "World Name"
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: textFieldWidth,
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a name for your Earth',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 4) Theme label + dropdown, aligned to top-right (but below text field).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Theme:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedTheme,
                        items: const [
                          DropdownMenuItem(
                            value: 'Light',
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: 'Dark',
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTheme = newValue;
                            });
                            logger.i('User selected theme: $newValue');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // 5) A "Save" button (centered by default in Column).
                  ElevatedButton(
                    onPressed: () {
                      logger.i(
                        'Save button clicked. (Name: ${_nameController.text}, '
                        'Theme: $_selectedTheme)',
                      );
                      // Future: Actually persist the new Earth, etc.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Save not yet implemented')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}