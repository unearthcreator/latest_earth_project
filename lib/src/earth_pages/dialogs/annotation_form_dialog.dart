import 'dart:io'; // For Image.file and File operations
import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // for getApplicationDocumentsDirectory
import 'package:path/path.dart' as p; // for path operations

Future<Map<String, String>?> showAnnotationFormDialog(
  BuildContext context, {
  required String title,
  required IconData chosenIcon,
  required String date,
}) async {
  logger.i('Showing annotation form dialog (icon, title, date, note).');
  final noteController = TextEditingController();
  String? selectedImagePath;

  return showDialog<Map<String, String>?>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SizedBox(
              width: screenWidth * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row with icon (left), title (center, bigger), date (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(chosenIcon),
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        Text(
                          date,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        hintText: 'Enter note',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          // Copy the image into the app's internal storage
                          final appDir = await getApplicationDocumentsDirectory();
                          final imagesDir = Directory(p.join(appDir.path, 'images'));

                          if (!await imagesDir.exists()) {
                            await imagesDir.create(recursive: true);
                          }

                          final fileName = p.basename(pickedFile.path);
                          final newPath = p.join(imagesDir.path, fileName);

                          await File(pickedFile.path).copy(newPath);

                          setState(() {
                            selectedImagePath = newPath; // Use the internal copy now
                          });

                          logger.i('User selected and copied image to: $selectedImagePath');
                        } else {
                          logger.i('User cancelled image selection.');
                        }
                      },
                      child: const Text('Add Image'),
                    ),
                    if (selectedImagePath != null) ...[
                      const SizedBox(height: 8),
                      Image.file(
                        File(selectedImagePath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 8),
                      Text('Selected image path: $selectedImagePath', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  logger.i('User cancelled annotation form dialog.');
                  Navigator.of(dialogContext).pop(null);
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  final note = noteController.text.trim();
                  logger.i('User pressed save in annotation form dialog, note=$note, imagePath=$selectedImagePath.');
                  Navigator.of(dialogContext).pop({
                    'note': note,
                    'imagePath': selectedImagePath ?? '',
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