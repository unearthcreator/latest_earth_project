import 'package:flutter/material.dart';
import 'package:map_mvp_project/src/earth_pages/earth_map_page.dart';
import 'package:map_mvp_project/services/error_handler.dart';

void handleCardTap(BuildContext context, int index, {String? worldId}) {
  if (index == 4 && worldId != null) {
    logger.i('Navigating to EarthMapPage for world with id: $worldId.');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EarthMapPage(worldId: worldId),
      ),
    );
  } else {
    logger.i('Navigating to EarthCreatorPage from card index $index.');
    Navigator.pushNamed(
      context,
      '/earth_creator',
      arguments: index, // Passing the index as the `arguments`
    );
  }
}