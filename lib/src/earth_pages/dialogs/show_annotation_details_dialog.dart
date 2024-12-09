import 'package:flutter/material.dart';
import 'package:map_mvp_project/models/annotation.dart';

Future<void> showAnnotationDetailsDialog(BuildContext context, Annotation ann) async {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon, title, date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon on the left
                  Image.asset(
                    'assets/icons/${ann.iconName}.png',
                    width: 32,
                    height: 32,
                  ),
                  // Title in the center
                  Expanded(
                    child: Center(
                      child: Text(
                        ann.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Date on the right
                  Text(
                    ann.date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ann.note), // Display the note as read-only text
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}