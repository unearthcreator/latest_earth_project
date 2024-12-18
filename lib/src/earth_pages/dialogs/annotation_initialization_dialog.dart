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
  String? initialEndDate,
}) async {
  logger.i('Showing initial form dialog (title, icon, date, endDate).');

  final titleController = TextEditingController(text: initialTitle ?? '');
  String chosenIconName = initialIconName ?? "cross";

  bool showDateFields = false;
  bool showSecondDateFields = false;

  final startMonthOrDayController = TextEditingController();
  final startDayOrMonthController = TextEditingController();
  final startYearController = TextEditingController();

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
          final loc = AppLocalizations.of(dialogContext)!;
          final localeName = loc.localeName;
          bool isUSLocale = localeName == 'en_US';

          final double containerWidth = screenWidth * 0.5;
          final double smallFieldWidth = containerWidth * 0.1;
          final double yearFieldWidth = containerWidth * 0.15;

          // Parse a given date string into controllers
          void parseDateString(String dateStr, TextEditingController firstC, TextEditingController secondC, TextEditingController yearC) {
            if (dateStr.isEmpty) return;
            // date format: US: MM-DD-YYYY, others: DD-MM-YYYY
            final parts = dateStr.split('-');
            if (parts.length != 3) return;

            final part1 = parts[0];
            final part2 = parts[1];
            final part3 = parts[2];

            if (isUSLocale) {
              // US: MM-DD-YYYY
              firstC.text = part1;  // MM
              secondC.text = part2; // DD
              yearC.text = part3;   // YYYY
            } else {
              // Non-US: DD-MM-YYYY
              // parts[0] = DD, parts[1] = MM, parts[2] = YYYY
              secondC.text = part1; // DD is first part, but for non-US firstC is day, secondC is month - check logic
              firstC.text = part2;  // Actually, we need to match the logic used in buildDateString
              // Wait, we must remember buildDateString:
              // Non-US: secondVal-firstVal-yearVal as DD-MM-YYYY.
              // secondVal = firstVal from code snippet above? Let's clarify:
              // buildDateString for non-US: return '$secondVal-$firstVal-$yearVal';
              // That means for non-US:
              //   secondVal was day
              //   firstVal was month
              // Actually, in the code above:
              // US: firstVal = month, secondVal = day
              // Non-US: firstVal = day? Actually, we must confirm from the original code.

              // Original code snippet:
              // If isUSLocale:
              //   firstVal = firstController => Month
              //   secondVal = secondController => Day
              // else (non-US):
              //   firstVal = firstController => day
              //   secondVal = secondController => month
              // Actually in the code, we set the labels:
              // Non-US: first field label = 'Day', second field label = 'Month'
              // So for Non-US:
              //   firstController = day
              //   secondController = month
              // buildDateString(non-US) = '$secondVal-$firstVal-$yearVal'
              // means $secondVal = month, $firstVal = day, but we said firstController=day, secondController=month?
              // The code for buildDateString might have a mixup. Let's fix the logic here:

              // Actually, from the code:
              // Non-US: first field => DayInputFormatter => day
              //          second field => MonthInputFormatter => month
              // buildDateString for non-US: '$secondVal-$firstVal-$yearVal'
              // If firstVal is day and secondVal is month, we got reversed in buildDateString. We must correct that.
              // Let's correct buildDateString logic now, since we see a discrepancy:

              // We'll define:
              // isUSLocale:
              //   firstController = month
              //   secondController = day
              //   buildDateString = '$firstVal-$secondVal-$yearVal' = MM-DD-YYYY
              //
              // Non-US:
              //   firstController = day
              //   secondController = month
              //   buildDateString = '$firstVal-$secondVal-$yearVal' = day-month-year (Correct)
              //
              // This means non-US is actually correct with firstVal=day, secondVal=month.
              // So if dateStr = DD-MM-YYYY non-US:
              // parts[0] = DD
              // parts[1] = MM
              // parts[2] = YYYY
              //
              // firstController = dayController = DD
              // secondController = monthController = MM
              // yearController = YYYY

              firstC.text = part1; // DD
              secondC.text = part2; // MM
              yearC.text = part3; // YYYY
            }
          }

          String buildDateString({
            required TextEditingController firstController,
            required TextEditingController secondController,
            required TextEditingController yearController,
            required bool isUSLocale,
          }) {
            final firstVal = firstController.text.trim();
            final secondVal = secondController.text.trim();
            final yearVal = yearController.text.trim();

            if (firstVal.isEmpty || secondVal.isEmpty || yearVal.isEmpty) {
              return '';
            }

            // US: MM-DD-YYYY
            // Non-US: DD-MM-YYYY (following the corrected logic)
            if (isUSLocale) {
              return '$firstVal-$secondVal-$yearVal';
            } else {
              return '$firstVal-$secondVal-$yearVal';
            }
          }

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
                      ? [MonthInputFormatter()] 
                      : [DayInputFormatter()],
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
                      ? [DayInputFormatter()]   
                      : [MonthInputFormatter()],
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

          // If initialDate is provided, parse it and show date fields
          if (initialDate != null && initialDate.isNotEmpty && !showDateFields) {
            setState(() {
              showDateFields = true;
              parseDateString(initialDate, startMonthOrDayController, startDayOrMonthController, startYearController);
            });
          }

          // If initialEndDate is provided, parse it and show second date fields
          if (initialEndDate != null && initialEndDate.isNotEmpty && !showSecondDateFields) {
            setState(() {
              showSecondDateFields = true;
              parseDateString(initialEndDate, endMonthOrDayController, endDayOrMonthController, endYearController);
            });
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
                        Image.asset(
                          'assets/icons/$chosenIconName.png',
                          width: 32,
                          height: 32,
                        ),
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
                          buildDateFields(
                            firstController: startMonthOrDayController,
                            secondController: startDayOrMonthController,
                            yearController: startYearController,
                          ),
                          const SizedBox(width: 8),
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
                  String date = '';
                  String endDate = '';
                  if (showDateFields) {
                    date = buildDateString(
                      firstController: startMonthOrDayController,
                      secondController: startDayOrMonthController,
                      yearController: startYearController,
                      isUSLocale: isUSLocale,
                    );
                    if (showSecondDateFields) {
                      endDate = buildDateString(
                        firstController: endMonthOrDayController,
                        secondController: endDayOrMonthController,
                        yearController: endYearController,
                        isUSLocale: isUSLocale,
                      );
                    }
                  }
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': date,
                    'endDate': endDate,
                    'quickSave': true,
                  });
                },
              ),
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  logger.i('Continue pressed in initial form dialog. Returning quickSave=false');
                  String date = '';
                  String endDate = '';
                  if (showDateFields) {
                    date = buildDateString(
                      firstController: startMonthOrDayController,
                      secondController: startDayOrMonthController,
                      yearController: startYearController,
                      isUSLocale: isUSLocale,
                    );
                    if (showSecondDateFields) {
                      endDate = buildDateString(
                        firstController: endMonthOrDayController,
                        secondController: endDayOrMonthController,
                        yearController: endYearController,
                        isUSLocale: isUSLocale,
                      );
                    }
                  }
                  Navigator.of(dialogContext).pop({
                    'title': titleController.text.trim(),
                    'icon': chosenIconName,
                    'date': date,
                    'endDate': endDate,
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
