import 'package:flutter/material.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:image_picker/image_picker.dart';

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
                          setState(() {
                            selectedImagePath = pickedFile.path;
                          });
                          logger.i('User selected image: $selectedImagePath');
                        } else {
                          logger.i('User cancelled image selection.');
                        }
                      },
                      child: const Text('Add Image'),
                    ),
                    if (selectedImagePath != null) ...[
                      const SizedBox(height: 8),
                      Text('Selected image path: $selectedImagePath', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]
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