import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/services/error_handler.dart';

void handleCardTap(BuildContext context, int index) {
  if (index == 4) {
    logger.i('Navigating to EarthMapPage from card index $index.');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EarthMapPage(),
      ),
    );
  } else {
    logger.i('Unhandled card interaction at index $index.');
  }
}