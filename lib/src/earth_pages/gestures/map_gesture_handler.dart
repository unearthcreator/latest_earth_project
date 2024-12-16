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

typedef AnnotationLongPressCallback = void Function(PointAnnotation annotation, Point annotationPosition);
typedef AnnotationDragUpdateCallback = void Function(PointAnnotation annotation);
typedef DragEndCallback = void Function();
typedef AnnotationRemovedCallback = void Function();

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
  final AnnotationLongPressCallback? onAnnotationLongPress;
  final AnnotationDragUpdateCallback? onAnnotationDragUpdate;
  final DragEndCallback? onDragEnd;
  final AnnotationRemovedCallback? onAnnotationRemoved;

  // New callback to notify when connect mode is disabled
  VoidCallback? onConnectModeDisabled;

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

  // New state for connect mode
  bool _isConnectMode = false;
  // Store the first annotation chosen in connect mode
  PointAnnotation? _firstConnectAnnotation;

  MapGestureHandler({
    required this.mapboxMap,
    required this.annotationsManager,
    required this.context,
    required this.localAnnotationsRepository,
    this.onAnnotationLongPress,
    this.onAnnotationDragUpdate,
    this.onDragEnd,
    this.onAnnotationRemoved,
    this.onConnectModeDisabled, // Add callback here
  }) : _trashCanHandler = TrashCanHandler(context: context) {
    annotationsManager.pointAnnotationManager.addOnPointAnnotationClickListener(
      MyPointAnnotationClickListener((clickedAnnotation) {
        logger.i('Annotation tapped: ${clickedAnnotation.id}');

        // If we're in connect mode, handle differently
        if (_isConnectMode) {
          _handleConnectModeClick(clickedAnnotation);
        } else {
          // Normal mode: show details
          final hiveId = _annotationIdMap[clickedAnnotation.id];
          if (hiveId != null) {
            _showAnnotationDetailsById(hiveId);
          } else {
            logger.w('No recorded Hive id for tapped annotation ${clickedAnnotation.id}');
          }
        }
      })
    );
  }

  // Enable connect mode and set the first annotation directly
  void enableConnectMode(PointAnnotation firstAnnotation) {
    logger.i('Connect mode enabled with first annotation: ${firstAnnotation.id}');
    _isConnectMode = true;
    _firstConnectAnnotation = firstAnnotation;
  }

  // Disable connect mode and notify page if callback is present
  void disableConnectMode() {
    logger.i('Connect mode disabled.');
    _isConnectMode = false;
    _firstConnectAnnotation = null;

    if (onConnectModeDisabled != null) {
      onConnectModeDisabled!();
    }
  }

  Future<void> _handleConnectModeClick(PointAnnotation clickedAnnotation) async {
    if (_firstConnectAnnotation == null) {
      // Shouldn't happen if enableConnectMode was called with an annotation
      logger.w('First connect annotation was null, but connect mode was enabled!');
      _firstConnectAnnotation = clickedAnnotation;
      logger.i('First annotation chosen for connection (fallback): ${clickedAnnotation.id}');
    } else {
      // We have a first annotation, now this is the second one
      logger.i('Second annotation chosen for connection: ${clickedAnnotation.id}');
      // TODO: Add logic here to draw a line between _firstConnectAnnotation and clickedAnnotation
      logger.i('Would draw a line between ${_firstConnectAnnotation!.id} and ${clickedAnnotation.id}');

      // After connecting, disable connect mode
      disableConnectMode();
    }
  }

  Future<void> _showAnnotationDetailsById(String id) async {
    final allAnnotations = await localAnnotationsRepository.getAnnotations();
    Annotation? ann;
    final found = allAnnotations.where((a) => a.id == id);
    ann = found.isEmpty ? null : found.first;

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
          // Call onAnnotationLongPress so EarthMapPage can show the menu
          if (onAnnotationLongPress != null) {
            onAnnotationLongPress!(_selectedAnnotation!, _originalPoint!);
          }
        } else {
          logger.w('No annotation found.');
        }
      }
    } catch (e) {
      logger.e('Error during feature query: $e');
    }
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

        // Notify EarthMapPage that drag updated
        if (onAnnotationDragUpdate != null) {
          onAnnotationDragUpdate!(annotationToUpdate);
        }
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

    if (annotationToRemove != null &&
        _lastDragScreenPoint != null &&
        _trashCanHandler.isOverTrashCan(_lastDragScreenPoint!)) {

      logger.i('Annotation ${annotationToRemove.id} dropped over trash can. Showing removal dialog.');
      final shouldRemove = await _showRemoveConfirmationDialog();

      if (shouldRemove == true) {
        logger.i('User confirmed removal - removing annotation ${annotationToRemove.id}.');
        await annotationsManager.removeAnnotation(annotationToRemove);
        // After successful removal, notify EarthMapPage
        if (onAnnotationRemoved != null) {
          onAnnotationRemoved!();
        }
      } else {
        logger.i('User cancelled removal - attempting to revert annotation to original position.');
        if (_originalPoint != null) {
          logger.i('Reverting annotation ${annotationToRemove.id} to ${_originalPoint?.coordinates}');
          await annotationsManager.updateVisualPosition(annotationToRemove, _originalPoint!);
        } else {
          logger.w('No original point stored, cannot revert.');
        }
      }
    }

    if (onDragEnd != null) {
      onDragEnd!();
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

          // Check if user wants a quickSave
          bool quickSave = initialData['quickSave'] == true;

          logger.i('Got title=$_chosenTitle, icon=$_chosenIconName, date=$_chosenDate, quickSave=$quickSave.');

          if (quickSave) {
            // User wants to skip the second dialog and just create the annotation
            final note = '';
            final imagePath = null;
            final filePath = null;

            if (_longPressPoint != null) {
              logger.i('Adding annotation (quickSave) at ${_longPressPoint?.coordinates}.');

              final bytes = await rootBundle.load('assets/icons/$_chosenIconName.png');
              final imageData = bytes.buffer.asUint8List();

              final mapAnnotation = await annotationsManager.addAnnotation(
                _longPressPoint!,
                image: imageData,
                title: _chosenTitle!,
                date: _chosenDate!
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
                imagePath: imagePath,
              );

              await localAnnotationsRepository.addAnnotation(annotation);
              logger.i('Annotation saved to Hive with id: $id');

              _annotationIdMap[mapAnnotation.id] = id;

              final savedAnnotations = await localAnnotationsRepository.getAnnotations();
              logger.i('Annotations currently in Hive: $savedAnnotations');

            } else {
              logger.w('No long press point stored, cannot place annotation (quickSave).');
            }

          } else {
            // Proceed with showing the second dialog (annotation_form_dialog)
            await startFormDialogFlow();
          }
        } else {
          logger.i('User closed the initial form dialog - no annotation added.');
        }
      } catch (e) {
        logger.e('Error in placement dialog timer: $e');
      }
    });
  }

  Future<void> startFormDialogFlow() async {
    logger.i('Showing annotation form dialog now.');
    final result = await showAnnotationFormDialog(
      context,
      title: _chosenTitle!,
      chosenIcon: Icons.star, // You can map _chosenIconName to a proper IconData if needed
      chosenIconName: _chosenIconName,
      date: _chosenDate!,
    );
    logger.i('Annotation form dialog returned: $result');

    if (result != null) {
      if (result['action'] == 'change') {
        // User wants to modify initial fields
        final changedTitle = result['title'] ?? '';
        final changedIcon = result['icon'] ?? 'cross';
        final changedDate = result['date'] ?? '';

        // Reopen the initialization dialog with the changed values
        logger.i('User chose to change initial fields. Reopening initialization dialog with prefilled values.');
        final secondInitResult = await showAnnotationInitializationDialog(
          context,
          initialTitle: changedTitle,
          initialIconName: changedIcon,
          initialDate: changedDate,
        );

        logger.i('Second initialization dialog returned: $secondInitResult');

        if (secondInitResult != null) {
          _chosenTitle = secondInitResult['title'] as String?;
          _chosenIconName = secondInitResult['icon'] as String;
          _chosenDate = secondInitResult['date'] as String?;

          bool newQuickSave = secondInitResult['quickSave'] == true;

          if (newQuickSave) {
            // Handle quick save logic again
            final note = '';
            final imagePath = null;
            final filePath = null;

            if (_longPressPoint != null) {
              logger.i('Adding annotation (quickSave after change) at ${_longPressPoint?.coordinates}.');

              final bytes = await rootBundle.load('assets/icons/$_chosenIconName.png');
              final imageData = bytes.buffer.asUint8List();

              final mapAnnotation = await annotationsManager.addAnnotation(
                _longPressPoint!,
                image: imageData,
                title: _chosenTitle!,
                date: _chosenDate!
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
                imagePath: imagePath,
              );

              await localAnnotationsRepository.addAnnotation(annotation);
              logger.i('Annotation saved to Hive with id: $id');

              _annotationIdMap[mapAnnotation.id] = id;

              final savedAnnotations = await localAnnotationsRepository.getAnnotations();
              logger.i('Annotations currently in Hive: $savedAnnotations');

            } else {
              logger.w('No long press point stored, cannot place annotation (quickSave after change).');
            }
          } else {
            // User pressed Continue again after Change, show the form dialog again
            await startFormDialogFlow(); // Run the form dialog flow again with updated values
          }
        } else {
          logger.i('User cancelled after choosing change - no annotation added.');
        }

      } else {
        // No action=change, means user either saved or cancelled the form dialog
        final note = result['note'] ?? '';
        final imagePath = result['imagePath'];
        final filePath = result['filePath'];
        logger.i('User entered note: $note, imagePath: $imagePath, filePath: $filePath');

        if (_longPressPoint != null && note != null) {
          logger.i('Adding annotation at ${_longPressPoint?.coordinates} with chosen data.');

          final bytes = await rootBundle.load('assets/icons/$_chosenIconName.png');
          final imageData = bytes.buffer.asUint8List();

          final mapAnnotation = await annotationsManager.addAnnotation(
            _longPressPoint!,
            image: imageData,
            title: _chosenTitle!,
            date: _chosenDate!
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
            imagePath: imagePath,
          );

          await localAnnotationsRepository.addAnnotation(annotation);
          logger.i('Annotation saved to Hive with id: $id');

          _annotationIdMap[mapAnnotation.id] = id;

          final savedAnnotations = await localAnnotationsRepository.getAnnotations();
          logger.i('Annotations currently in Hive: $savedAnnotations');

        } else {
          logger.i('User cancelled the annotation note dialog or no long press point stored - no annotation added.');
        }
      }
    } else {
      logger.i('User cancelled the annotation form dialog - no annotation added.');
    }
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
  }

  void registerAnnotationId(String mapAnnotationId, String hiveId) {
    _annotationIdMap[mapAnnotationId] = hiveId;
  }

  String? getHiveIdForAnnotation(PointAnnotation annotation) {
    return _annotationIdMap[annotation.id];
  }

  String? getHiveIdForAnnotationId(String mapAnnotationId) {
    return _annotationIdMap[mapAnnotationId];
  }

  void startDraggingSelectedAnnotation() {
    logger.i('User chose to move annotation. Starting drag mode.');
    _isDragging = true;
    _isProcessingDrag = false;
    _trashCanHandler.showTrashCan();
  }

  void hideTrashCanAndStopDragging() {
    logger.i('Locking annotation in place and hiding trash can.');
    _isDragging = false;
    _isProcessingDrag = false;
    _trashCanHandler.hideTrashCan();
  }
}
