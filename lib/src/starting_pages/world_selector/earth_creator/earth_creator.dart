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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Earth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Text field for "world name"
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'World Name',
                hintText: 'Enter a name for your Earth',
              ),
            ),
            const SizedBox(height: 20),

            // 2) A simple dropdown for choosing “Light” or “Dark” theme
            Row(
              children: [
                const Text(
                  'Theme:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedTheme,
                  items: const [
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
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
            const SizedBox(height: 40),

            // 3) A "Save" button that does nothing yet
            ElevatedButton(
              onPressed: () {
                logger.i('Save button clicked. (Name: ${_nameController.text}, Theme: $_selectedTheme)');
                // Future: Actually persist the new Earth, etc.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save not yet implemented')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}