import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for rootBundle
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/annotations/map_annotations_manager.dart';
import 'package:map_mvp_project/src/earth_pages/dialogs/annotation_initialization_dialog.dart';
import 'package:map_mvp_project/src/earth_pages/dialogs/annotation_form_dialog.dart';
import 'package:map_mvp_project/src/earth_pages/dialogs/show_annotation_details_dialog.dart';
import 'package:map_mvp_project/src/earth_pages/utils/trash_can_handler.dart';
import 'package:uuid/uuid.dart'; // for unique IDs
import 'package:map_mvp_project/models/annotation.dart'; // Your Annotation model
import 'package:map_mvp_project/repositories/local_annotations_repository.dart'; // Your local repo

class MyPointAnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation) onClick;

  MyPointAnnotationClickListener(this.onClick);

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onClick(annotation);
    return true; // event handled
  }
}

class MapGestureHandler {
  final MapboxMap mapboxMap;
  final MapAnnotationsManager annotationsManager;
  final BuildContext context;
  final LocalAnnotationsRepository localAnnotationsRepository;

  Timer? _longPressTimer;
  Timer? _placementDialogTimer;
  Point? _longPressPoint;
  bool _isOnExistingAnnotation = false;
  PointAnnotation? _selectedAnnotation;
  bool _isDragging = false;
  bool _isProcessingDrag = false;
  final TrashCanHandler _trashCanHandler;
  ScreenCoordinate? _lastDragScreenPoint;
  Point? _originalPoint;

  final Map<String, String> _annotationIdMap = {};

  String? _chosenTitle;
  String? _chosenDate;
  String _chosenIconName = "mapbox-check"; // Default icon
  final uuid = Uuid();

  MapGestureHandler({
    required this.mapboxMap,
    required this.annotationsManager,
    required this.context,
    required this.localAnnotationsRepository,
  }) : _trashCanHandler = TrashCanHandler(context: context) {
    annotationsManager.pointAnnotationManager.addOnPointAnnotationClickListener(
      MyPointAnnotationClickListener((clickedAnnotation) {
        logger.i('Annotation tapped: ${clickedAnnotation.id}');
        final hiveId = _annotationIdMap[clickedAnnotation.id];
        if (hiveId != null) {
          _showAnnotationDetailsById(hiveId);
        } else {
          logger.w('No recorded Hive id for tapped annotation ${clickedAnnotation.id}');
        }
      })
    );
  }

  Future<void> _showAnnotationDetailsById(String id) async {
    final allAnnotations = await localAnnotationsRepository.getAnnotations();
    Annotation? ann;
    try {
      ann = allAnnotations.firstWhere((a) => a.id == id);
    } catch (e) {
      ann = null; // If not found, set to null
    }

    if (ann != null) {
      showAnnotationDetailsDialog(context, ann);
    } else {
      logger.w('No matching Hive annotation found for id: $id');
    }
  }

  Future<void> handleLongPress(ScreenCoordinate screenPoint) async {
    try {
      final features = await mapboxMap.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(screenPoint),
        RenderedQueryOptions(layerIds: [annotationsManager.annotationLayerId]),
      );

      logger.i('Features found: ${features.length}');
      final pressPoint = await mapboxMap.coordinateForPixel(screenPoint);
      if (pressPoint == null) {
        logger.w('Could not convert screen coordinate to map coordinate');
        return;
      }

      _longPressPoint = pressPoint;
      _isOnExistingAnnotation = features.isNotEmpty;

      if (!_isOnExistingAnnotation) {
        logger.i('No existing annotation, will start placement dialog timer.');
        _startPlacementDialogTimer(pressPoint);
      } else {
        logger.i('Long press on existing annotation.');
        _selectedAnnotation = await annotationsManager.findNearestAnnotation(pressPoint);
        if (_selectedAnnotation != null) {
          try {
            _originalPoint = Point.fromJson({
              'type': 'Point',
              'coordinates': [
                _selectedAnnotation!.geometry.coordinates[0],
                _selectedAnnotation!.geometry.coordinates[1]
              ],
            });
            logger.i('Original point stored: ${_originalPoint?.coordinates} for annotation ${_selectedAnnotation?.id}');
          } catch (e) {
            logger.e('Error storing original point: $e');
          }
          _startDragTimer();
        } else {
          logger.w('No annotation found to start dragging.');
        }
      }
    } catch (e) {
      logger.e('Error during feature query: $e');
    }
  }

  void _startDragTimer() {
    _longPressTimer?.cancel();
    logger.i('Starting drag timer.');
    _longPressTimer = Timer(const Duration(seconds: 1), () {
      logger.i('Drag timer completed - annotation can now be dragged.');
      _isDragging = true;
      _isProcessingDrag = false;
      _trashCanHandler.showTrashCan();
    });
  }

  Future<void> handleDrag(ScreenCoordinate screenPoint) async {
    if (!_isDragging || _selectedAnnotation == null) return;

    final annotationToUpdate = _selectedAnnotation;
    if (annotationToUpdate == null || _isProcessingDrag) return;

    try {
      _isProcessingDrag = true;
      _lastDragScreenPoint = screenPoint;
      final newPoint = await mapboxMap.coordinateForPixel(screenPoint);

      if (!_isDragging || _selectedAnnotation == null) return;
      if (newPoint != null) {
        logger.i('Updating annotation ${annotationToUpdate.id} position to $newPoint');
        await annotationsManager.updateVisualPosition(annotationToUpdate, newPoint);
      }
    } catch (e) {
      logger.e('Error during drag: $e');
    } finally {
      _isProcessingDrag = false;
    }
  }

  Future<void> endDrag() async {
    logger.i('Ending drag.');
    logger.i('Original point at end drag: ${_originalPoint?.coordinates}');
    final annotationToRemove = _selectedAnnotation;
    bool removedAnnotation = false;
    bool revertedPosition = false;

    if (annotationToRemove != null &&
        _lastDragScreenPoint != null &&
        _trashCanHandler.isOverTrashCan(_lastDragScreenPoint!)) {
      
      logger.i('Annotation ${annotationToRemove.id} dropped over trash can. Showing removal dialog.');
      final shouldRemove = await _showRemoveConfirmationDialog();

      if (shouldRemove == true) {
        logger.i('User confirmed removal - removing annotation ${annotationToRemove.id}.');
        await annotationsManager.removeAnnotation(annotationToRemove);
        removedAnnotation = true;
      } else {
        logger.i('User cancelled removal - attempting to revert annotation to original position.');
        if (_originalPoint != null) {
          logger.i('Reverting annotation ${annotationToRemove.id} to ${_originalPoint?.coordinates}');
          await annotationsManager.updateVisualPosition(annotationToRemove, _originalPoint!);
          revertedPosition = true;
        } else {
          logger.w('No original point stored, cannot revert.');
        }
      }
    }

    _selectedAnnotation = null;
    _isDragging = false;
    _isProcessingDrag = false;
    _lastDragScreenPoint = null;
    _originalPoint = null;
    _trashCanHandler.hideTrashCan();

    if (removedAnnotation) {
      logger.i('Annotation removed successfully.');
    } else if (revertedPosition) {
      logger.i('Annotation reverted to original position.');
    } else {
      logger.i('No removal or revert occurred.');
    }
  }

  Future<bool?> _showRemoveConfirmationDialog() async {
    logger.i('Showing remove confirmation dialog.');
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Annotation'),
          content: const Text('Do you want to remove this annotation?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                logger.i('User selected NO in remove dialog.');
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                logger.i('User selected YES in remove dialog.');
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _startPlacementDialogTimer(Point point) {
    _placementDialogTimer?.cancel();
    logger.i('Starting placement dialog timer for annotation at $point.');
    _placementDialogTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        logger.i('Attempting to show initial form dialog now.');
        final initialData = await showAnnotationInitializationDialog(context);
        logger.i('Initial form dialog returned: $initialData');
        if (initialData != null) {
          _chosenTitle = initialData['title'] as String;
          _chosenIconName = initialData['icon'] as String;
          _chosenDate = initialData['date'] as String;

          logger.i('Got title=$_chosenTitle, icon=$_chosenIconName, date=$_chosenDate from initial dialog. Showing annotation form dialog next.');
          final result = await showAnnotationFormDialog(
            context,
            title: _chosenTitle!,
            chosenIcon: Icons.star,
            date: _chosenDate!,
          );
          logger.i('Annotation form dialog returned: $result');
          if (result != null) {
            final note = result['note'] ?? '';
            final imagePath = result['imagePath']; // Get the image path if returned
            logger.i('User entered note: $note, imagePath: $imagePath');

            if (_longPressPoint != null) {
              logger.i('Adding annotation at ${_longPressPoint?.coordinates} with chosen data.');

              final bytes = await rootBundle.load('assets/icons/$_chosenIconName.png');
              final imageData = bytes.buffer.asUint8List();

              final mapAnnotation = await annotationsManager.addAnnotation(
                _longPressPoint!,
                image: imageData,
              );

              logger.i('Annotation added successfully at ${_longPressPoint?.coordinates}');

              final id = uuid.v4();
              final latitude = _longPressPoint!.coordinates.lat.toDouble();
              final longitude = _longPressPoint!.coordinates.lng.toDouble();

              final annotation = Annotation(
                id: id,
                title: _chosenTitle!,
                iconName: _chosenIconName,
                date: _chosenDate!,
                note: note,
                latitude: latitude,
                longitude: longitude,
                imagePath: imagePath, // Pass the image path here
              );

              await localAnnotationsRepository.addAnnotation(annotation);
              logger.i('Annotation saved to Hive with id: $id');

              _annotationIdMap[mapAnnotation.id] = id;

              final savedAnnotations = await localAnnotationsRepository.getAnnotations();
              logger.i('Annotations currently in Hive: $savedAnnotations');

            } else {
              logger.w('No long press point stored, cannot place annotation.');
            }

          } else {
            logger.i('User cancelled the annotation note dialog - no annotation added.');
          }
        } else {
          logger.i('User closed the initial form dialog - no annotation added.');
        }
      } catch (e) {
        logger.e('Error in placement dialog timer: $e');
      }
    });
  }

  void cancelTimer() {
    logger.i('Cancelling timers and resetting state');
    _longPressTimer?.cancel();
    _placementDialogTimer?.cancel();
    _longPressTimer = null;
    _placementDialogTimer = null;
    _longPressPoint = null;
    _selectedAnnotation = null;
    _isOnExistingAnnotation = false;
    _isDragging = false;
    _isProcessingDrag = false;
    _originalPoint = null;
    _trashCanHandler.hideTrashCan();
  }

  void dispose() {
    cancelTimer();
  }

  bool get isDragging => _isDragging;
  PointAnnotation? get selectedAnnotation => _selectedAnnotation;
}