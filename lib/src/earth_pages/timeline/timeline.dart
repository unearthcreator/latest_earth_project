import 'package:flutter/material.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: CustomPaint(
        painter: _TimelinePainter(),
        child: Container(), // just an empty container for now
      ),
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  @override  // Add this annotation
  void paint(Canvas canvas, Size size) {
    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // A simple line
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), linePaint);
  }

  @override  // This was already present
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}