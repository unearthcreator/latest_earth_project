import 'package:flutter/material.dart';
import 'dart:ui' as ui; // We'll use ui.Size for clarity
import 'package:map_mvp_project/src/earth_pages/timeline/painter/utils/timeline_axis.dart'; 
// Adjust the import path accordingly to your actual folder structure

class TimelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, ui.Size size) {
    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Now we draw the bottom axis line using our utility function
    drawTimelineAxis(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TimelinePainter(),
      // The parent (earth_map_page) will size this widget as needed.
    );
  }
}