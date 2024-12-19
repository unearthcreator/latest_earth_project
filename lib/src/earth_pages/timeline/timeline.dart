import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/earth_pages/timeline/utils/timeline_painter.dart'; 
// Adjust the import path according to your project's structure

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TimelinePainter(), // Now using the painter from timeline_painter.dart
    );
  }
}