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
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    if (text.length > 2) return oldValue;
    final month = int.tryParse(text);
    if (month == null || month < 1 || month > 12) return oldValue;
    return newValue;
  }
}

class DayInputFormatter extends TextInputFormatter {
  // Day should be 1-31.
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    if (text.length > 2) return oldValue;
    final day = int.tryParse(text);
    if (day == null || day < 1 || day > 31) return oldValue;
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

  bool showDateFields = false;       // Flag to show/hide the start date fields
  bool showSecondDateFields = false; // Flag to show/hide the end date fields

  // Controllers for the first (start) date
  final startMonthOrDayController = TextEditingController();
  final startDayOrMonthController = TextEditingController();
  final startYearController = TextEditingController();

  // Controllers for the second (end) date
  final endMonthOrDayController = TextEditingController();
  final endDayOrMonthController = TextEditingController();
  final endYearController = TextEditingController();

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

          final double containerWidth = screenWidth * 0.5; 
          final double smallFieldWidth = containerWidth * 0.1; // small width for month/day
          final double yearFieldWidth = containerWidth * 0.15; // reduced width for year

          Widget buildDateFields({
            required TextEditingController firstController,
            required TextEditingController secondController,
            required TextEditingController yearController,
          }) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: smallFieldWidth,
                  child: TextField(
                    controller: firstController,
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
                SizedBox(
                  width: smallFieldWidth,
                  child: TextField(
                    controller: secondController,
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
                SizedBox(
                  width: yearFieldWidth,
                  child: TextField(
                    controller: yearController,
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
            );
          }

          return AlertDialog(
            content: SizedBox(
              width: containerWidth,
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
                      // Now we put everything in one Row: start date fields, plus button, and end date fields if visible
                      Row(
                        children: [
                          // Start date fields
                          buildDateFields(
                            firstController: startMonthOrDayController,
                            secondController: startDayOrMonthController,
                            yearController: startYearController,
                          ),
                          const SizedBox(width: 8),
                          // Plus button to add second date
                          InkWell(
                            onTap: () {
                              logger.i('Plus button clicked for interval');
                              setState(() {
                                showSecondDateFields = true;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                          if (showSecondDateFields) ...[
                            const SizedBox(width: 8),
                            // End date fields
                            buildDateFields(
                              firstController: endMonthOrDayController,
                              secondController: endDayOrMonthController,
                              yearController: endYearController,
                            ),
                          ],
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
