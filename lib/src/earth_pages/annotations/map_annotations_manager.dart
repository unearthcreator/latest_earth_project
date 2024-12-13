import 'dart:typed_data';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/services/error_handler.dart';

class MapAnnotationsManager {
  final PointAnnotationManager _annotationManager;
  final List<PointAnnotation> _annotations = [];
 
  MapAnnotationsManager(this._annotationManager);

  // Add a getter to access the underlying annotation manager
  PointAnnotationManager get pointAnnotationManager => _annotationManager;

  Future<PointAnnotation> addAnnotation(
    Point mapPoint, {
    Uint8List? image,
    String? title,
    String? date,
  }) async {
    logger.i('Adding annotation at: ${mapPoint.coordinates.lat}, ${mapPoint.coordinates.lng}');
    
    final hasTitle = title != null && title.isNotEmpty;
    final hasDate = date != null && date.isNotEmpty;

    String? displayText;
    if (hasTitle && hasDate) {
      // Two lines: title then date
      displayText = "$title\n$date";
    } else if (hasTitle) {
      displayText = title;
    } else if (hasDate) {
      displayText = date;
    } else {
      displayText = null;
    }

    // If no custom image is provided, we use a default sprite icon from the style
    // "marker-15" is a common sprite icon available in the default styles.
    final iconImageName = (image == null) ? "marker-15" : null;

    final annotationOptions = PointAnnotationOptions(
      geometry: mapPoint,
      iconSize: 5.0,
      image: image,
      iconImage: iconImageName, // Use default sprite if no custom image is provided
      textField: displayText,
      textSize: (displayText != null) ? 18.0 : null,
      textAnchor: (displayText != null) ? TextAnchor.BOTTOM : null,
      iconAnchor: IconAnchor.BOTTOM,
      textOffset: (displayText != null) ? [0, -2.1] : null,
      textLineHeight: (hasTitle && hasDate) ? 1.2 : null,
      textColor: (displayText != null) ? 0xFFFFFFFF : null,   // White text
      textHaloColor: (displayText != null) ? 0xFF000000 : null, // Black halo
      textHaloWidth: (displayText != null) ? 1.0 : null,
      textHaloBlur: (displayText != null) ? 0.5 : null,
    );

    logger.i('title=$title, date=$date, displayText="$displayText"');
    final annotation = await _annotationManager.create(annotationOptions);
    _annotations.add(annotation);
    logger.i('Added annotation, total count: ${_annotations.length}');
    return annotation;
  }

  Future<void> removeAnnotation(PointAnnotation annotation) async {
    logger.i('Attempting to remove annotation');
    try {
      await _annotationManager.delete(annotation);
      final removed = _annotations.remove(annotation);
      if (removed) {
        logger.i('Successfully removed annotation from list, remaining: ${_annotations.length}');
      } else {
        logger.w('Annotation was not found in list');
      }
    } catch (e) {
      logger.e('Error during annotation removal: $e');
      throw e;
    }
  }

  Future<void> updateVisualPosition(PointAnnotation annotation, Point newPoint) async {
    try {
      annotation.geometry = newPoint;
      await _annotationManager.update(annotation);
      logger.i('Updated annotation visual position to: ${newPoint.coordinates.lat}, ${newPoint.coordinates.lng}');
    } catch (e) {
      logger.e('Error updating annotation visual position: $e');
      throw e;
    }
  }

  Future<PointAnnotation?> findNearestAnnotation(Point tapPoint) async {
    if (_annotations.isEmpty) {
      logger.i('No annotations to search through');
      return null;
    }
    double minDistance = double.infinity;
    PointAnnotation? nearest;
   
    for (var annotation in _annotations) {
      double distance = _calculateDistance(annotation.geometry, tapPoint);
      logger.i('Checking annotation distance: $distance');
      if (distance < minDistance) {
        minDistance = distance;
        nearest = annotation;
      }
    }
   
    if (nearest != null) {
      logger.i('Found nearest annotation at distance: $minDistance');
    }
   
    return minDistance < 2.0 ? nearest : null;
  }

  double _calculateDistance(Point p1, Point p2) {
    double latDiff = (p1.coordinates.lat.toDouble() - p2.coordinates.lat.toDouble()).abs();
    double lngDiff = (p1.coordinates.lng.toDouble() - p2.coordinates.lng.toDouble()).abs();
    return latDiff + lngDiff;
  }

  String get annotationLayerId => _annotationManager.id;
  bool get hasAnnotations => _annotations.isNotEmpty;
  List<PointAnnotation> get annotations => List.unmodifiable(_annotations);
}