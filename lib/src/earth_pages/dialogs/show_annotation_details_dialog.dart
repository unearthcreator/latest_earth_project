import 'dart:io';
import 'package:flutter/material.dart';
import 'package:map_mvp_project/models/annotation.dart';
import 'package:map_mvp_project/services/error_handler.dart';

Future<void> showAnnotationDetailsDialog(BuildContext context, Annotation annotation) async {
  logger.i('Showing details dialog for annotation: ${annotation.id}');
  
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      return AlertDialog(
        content: SizedBox(
          width: screenWidth * 0.5, // 50% of screen width
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row with icon (if you have one), title, date
                // For now, if we have iconName, we might not be able to show the custom icon easily.
                // Assume we just show title and date similarly as before.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // If you have a way to show the chosenIcon as before, you can add it here.
                    // For now, assume just title and date.
                    Text(
                      annotation.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    Text(
                      annotation.date,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  annotation.note.isNotEmpty ? annotation.note : 'No note provided',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (annotation.imagePath != null && annotation.imagePath!.isNotEmpty) ...[
                  const Text('Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Image.file(
                    File(annotation.imagePath!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}