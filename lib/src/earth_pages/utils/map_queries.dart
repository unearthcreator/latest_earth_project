import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/services/error_handler.dart'; // for logger
import 'package:map_mvp_project/src/earth_pages/annotations/map_annotations_manager.dart'; // for annotationsManager

Future<void> queryVisibleFeatures({
  required BuildContext context,
  required bool isMapReady,
  required MapboxMap mapboxMap,
  required MapAnnotationsManager annotationsManager,
}) async {
  if (!isMapReady) return;

  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;

  final features = await mapboxMap.queryRenderedFeatures(
    RenderedQueryGeometry.fromScreenBox(
      ScreenBox(
        min: ScreenCoordinate(x: 0, y: 0),
        max: ScreenCoordinate(x: width, y: height),
      ),
    ),
    RenderedQueryOptions(
      layerIds: [annotationsManager.annotationLayerId],
      filter: null,
    ),
  );

  logger.i('Viewport features found: ${features.length}');
}