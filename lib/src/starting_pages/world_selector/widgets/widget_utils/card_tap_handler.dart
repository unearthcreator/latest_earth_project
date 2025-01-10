import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/services/error_handler.dart';

void handleCardTap(BuildContext context, int index) {
  logger.i('handleCardTap called with index $index.');

  // Validate context for navigation
  if (!Navigator.canPop(context)) {
    logger.w('Navigator context cannot handle navigation.');
    return;
  }

  if (index == 4) {
    logger.i('Attempting to navigate to EarthMapPage.');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            logger.i('Building EarthMapPage widget.');
            return const EarthMapPage();
          },
        ),
      ).then((_) {
        logger.i('EarthMapPage navigation completed successfully.');
      }).catchError((error, stack) {
        logger.e('Error during EarthMapPage navigation', error: error, stackTrace: stack);
      });
    } catch (e, stackTrace) {
      logger.e('Unexpected error navigating to EarthMapPage', error: e, stackTrace: stackTrace);
    }
  } else {
    logger.i('Navigating to EarthCreatorPage with index $index.');
    try {
      Navigator.pushNamed(
        context,
        '/earth_creator',
        arguments: index,
      ).catchError((error, stack) {
        logger.e('Error navigating to EarthCreatorPage', error: error, stackTrace: stack);
      });
    } catch (e, stackTrace) {
      logger.e('Unexpected error navigating to EarthCreatorPage', error: e, stackTrace: stackTrace);
    }
  }
}