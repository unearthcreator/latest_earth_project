import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';

Future<Map<String, dynamic>?> showAnnotationInitializationDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialIconName,
  String? initialDate,
}) async {
  logger.i('Showing initial form dialog (title, icon, date).');
  
  // Use the initial values if provided, otherwise default to empty strings and "cross"
  final titleController = TextEditingController(text: initialTitle ?? '');
  final dateController = TextEditingController(text: initialDate ?? '');
  String chosenIconName = initialIconName ?? "cross";

  return showDialog<Map<String, dynamic>?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      return StatefulBuilder(
        builder: (context, setState) {
          Widget currentIconWidget = Image.asset(
            'assets/icons/$chosenIconName.png',
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
                child: const Text('Save'),
                onPressed: () {
                  logger.i('Save pressed in initial form dialog. Creating annotation immediately.');
                  logger.i('Returning title=${titleController.text.trim()}, icon=$chosenIconName, date=${dateController.text.trim()} with quickSave=true');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': dateController.text.trim(),
                    'quickSave': true,
                  });
                },
              ),
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  logger.i('Continue pressed in initial form dialog.');
                  logger.i('Returning title=${titleController.text.trim()}, icon=$chosenIconName, date=${dateController.text.trim()}');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': dateController.text.trim(),
                    'quickSave': false,
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
                    Image.asset(
                      'assets/icons/$iconName.png',
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