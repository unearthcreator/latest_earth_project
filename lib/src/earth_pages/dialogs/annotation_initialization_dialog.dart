import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/l10n/app_localizations.dart';

class YearInputFormatter extends TextInputFormatter {
  final RegExp _yearRegex = RegExp(r'^-?\d{0,4}$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (_yearRegex.hasMatch(newValue.text)) {
      return newValue;
    } else {
      return oldValue;
    }
  }
}

class MonthInputFormatter extends TextInputFormatter {
  // Month should be 1-12.
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Empty is allowed while typing.
    if (text.isEmpty) return newValue;

    // Only digits allowed.
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;

    // If more than 2 digits, revert.
    if (text.length > 2) return oldValue;

    // Parse the number.
    final month = int.tryParse(text);
    if (month == null) return oldValue;

    // Check range.
    if (month < 1 || month > 12) {
      return oldValue;
    }

    return newValue;
  }
}

class DayInputFormatter extends TextInputFormatter {
  // Day should be 1-31.
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // Empty is allowed while typing.
    if (text.isEmpty) return newValue;

    // Only digits allowed.
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;

    // If more than 2 digits, revert.
    if (text.length > 2) return oldValue;

    // Parse the number.
    final day = int.tryParse(text);
    if (day == null) return oldValue;

    // Check range.
    if (day < 1 || day > 31) {
      return oldValue;
    }

    return newValue;
  }
}

Future<Map<String, dynamic>?> showAnnotationInitializationDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialIconName,
  String? initialDate,
}) async {
  logger.i('Showing initial form dialog (title, icon).');
  
  final titleController = TextEditingController(text: initialTitle ?? '');
  String chosenIconName = initialIconName ?? "cross";

  bool showDateFields = false; // Flag to show/hide the date fields

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

          final loc = AppLocalizations.of(dialogContext)!;
          final localeName = loc.localeName; 
          bool isUSLocale = localeName == 'en_US';

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
                          return null; 
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
                    ElevatedButton(
                      onPressed: () {
                        logger.i('Add Date button clicked');
                        setState(() {
                          showDateFields = true;
                        });
                      },
                      child: const Text('Add Date'),
                    ),
                    if (showDateFields) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: isUSLocale ? 'MM' : 'DD',
                                labelText: isUSLocale ? 'Month' : 'Day',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: isUSLocale 
                                ? [MonthInputFormatter()] // US: first field is month
                                : [DayInputFormatter()],   // Non-US: first field is day
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: isUSLocale ? 'DD' : 'MM',
                                labelText: isUSLocale ? 'Day' : 'Month',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: isUSLocale
                                ? [DayInputFormatter()]   // US: second field is day
                                : [MonthInputFormatter()], // Non-US: second field is month
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'YYYY',
                                labelText: 'Year',
                              ),
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                YearInputFormatter(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  logger.i('Save pressed in initial form dialog. Returning quickSave=true');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': '', 
                    'quickSave': true,
                  });
                },
              ),
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  logger.i('Continue pressed in initial form dialog. Returning quickSave=false');
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': '', 
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