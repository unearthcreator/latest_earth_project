import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For SvgPicture
import 'package:map_mvp_project/services/error_handler.dart';

Future<Map<String, dynamic>?> showAnnotationInitializationDialog(BuildContext context) async {
  logger.i('Showing initial form dialog (title, icon, date).');
  final titleController = TextEditingController();
  final dateController = TextEditingController();

  // Default to "cross" icon
  String chosenIconName = "cross";

  return showDialog<Map<String, dynamic>?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      return StatefulBuilder(
        builder: (context, setState) {
          Widget currentIconWidget = SvgPicture.asset(
            'assets/icons/$chosenIconName.svg',
            width: 32,
            height: 32,
          );

          return AlertDialog(
            content: SizedBox(
              width: screenWidth * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            logger.i('Close icon tapped in initial form dialog.');
                            Navigator.of(dialogContext).pop(null);
                          },
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Title:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: titleController,
                      maxLength: 25,
                      decoration: InputDecoration(
                        hintText: 'Max 25 characters',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        counterText: '',
                      ),
                      buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) {
                        if (maxLength == null) return null;
                        if (currentLength == 0) {
                          return null; // No counter if no characters typed
                        } else {
                          return Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        currentIconWidget,
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            logger.i('Opening icon selection dialog from initial form dialog.');
                            final selectedIconName = await _showMapboxIconSelectionDialog(dialogContext);
                            logger.i('Icon selection dialog returned: $selectedIconName');
                            if (selectedIconName != null) {
                              setState(() {
                                chosenIconName = selectedIconName;
                              });
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        hintText: 'Enter date',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  logger.i('Continue pressed in initial form dialog.');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName, // now a string name from svg
                    'date': dateController.text.trim(),
                  });
                },
              ),
            ],
          );
        },
      );
    },
  );
}

// Shows a dialog with cricket.svg and cinema.svg as options
Future<String?> _showMapboxIconSelectionDialog(BuildContext dialogContext) async {
  final mapboxIcons = [
    "cricket",
    "cinema",
  ];

  return showDialog<String>(
    context: dialogContext,
    builder: (iconDialogContext) {
      return AlertDialog(
        title: const Text('Select an Icon'),
        content: SizedBox(
          width: MediaQuery.of(iconDialogContext).size.width * 0.5,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: mapboxIcons.map((iconName) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(iconDialogContext).pop(iconName);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/$iconName.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(iconName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}