import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart'; // for rootBundle
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/repositories/local_annotations_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/annotations/map_annotations_manager.dart';
import 'package:map_mvp_project/src/earth_pages/gestures/map_gesture_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/trash_can_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:map_mvp_project/services/geocoding_service.dart';
import 'package:uuid/uuid.dart'; // for generating unique IDs
import 'package:map_mvp_project/models/annotation.dart'; // for Annotation model

class EarthMapPage extends StatefulWidget {
  const EarthMapPage({super.key});

  @override
  EarthMapPageState createState() => EarthMapPageState();
}

class EarthMapPageState extends State<EarthMapPage> {
  late MapboxMap _mapboxMap;
  late MapAnnotationsManager _annotationsManager;
  late MapGestureHandler _gestureHandler;
  late LocalAnnotationsRepository _localRepo;

  bool _isMapReady = false;
  bool _isError = false;
  String _errorMessage = '';

  final TextEditingController _addressController = TextEditingController();
  bool _showSearchBar = false;

  List<String> _suggestions = [];
  Timer? _debounceTimer;

  final uuid = Uuid(); // for unique IDs

  // For annotation menu
  bool _showAnnotationMenu = false;
  PointAnnotation? _annotationMenuAnnotation;
  Offset _annotationMenuOffset = Offset.zero;

  bool _isDragging = false; // Are we in drag (move) mode?
  String get _annotationButtonText => _isDragging ? 'Lock' : 'Move';

  @override
  void initState() {
    super.initState();
    logger.i('Initializing EarthMapPage');
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAddressChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final query = _addressController.text.trim();
      if (query.isNotEmpty) {
        final suggestions = await GeocodingService.fetchAddressSuggestions(query);
        setState(() {
          _suggestions = suggestions;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    try {
      logger.i('Starting map initialization');
      _mapboxMap = mapboxMap;

      final annotationManager = await mapboxMap.annotations
          .createPointAnnotationManager()
          .onError((error, stackTrace) {
        logger.e('Failed to create annotation manager', error: error, stackTrace: stackTrace);
        throw Exception('Failed to initialize map annotations');
      });

      _annotationsManager = MapAnnotationsManager(annotationManager);
      _localRepo = LocalAnnotationsRepository();

      _gestureHandler = MapGestureHandler(
        mapboxMap: mapboxMap,
        annotationsManager: _annotationsManager,
        context: context,
        localAnnotationsRepository: _localRepo,
        onAnnotationLongPress: _handleAnnotationLongPress,
        onAnnotationDragUpdate: _handleAnnotationDragUpdate,
        onDragEnd: _handleDragEnd,
      );

      logger.i('Map initialization completed successfully');

      if (mounted) {
        setState(() => _isMapReady = true);
      }
    } catch (e, stackTrace) {
      logger.e('Error during map initialization', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to initialize map: ${e.toString()}';
        });
      }
    }
  }

  void _handleAnnotationLongPress(PointAnnotation annotation, Point annotationPosition) async {
    final screenPos = await _mapboxMap.pixelForCoordinate(annotationPosition);
    setState(() {
      _annotationMenuAnnotation = annotation;
      _showAnnotationMenu = true;
      // Position menu slightly to the right of annotation
      _annotationMenuOffset = Offset(screenPos.x + 30, screenPos.y);
    });
  }

  void _handleAnnotationDragUpdate(PointAnnotation annotation) async {
    // Update the button position as annotation moves
    final screenPos = await _mapboxMap.pixelForCoordinate(annotation.geometry);
    setState(() {
      _annotationMenuAnnotation = annotation;
      _annotationMenuOffset = Offset(screenPos.x + 30, screenPos.y);
    });
  }

  void _handleDragEnd() {
    // Drag ended - we do nothing special here, the button stays
    // User can still move unless locked
  }

  void _handleLongPress(LongPressStartDetails details) {
    try {
      logger.i('Long press started at: ${details.localPosition}');
      final screenPoint = ScreenCoordinate(
        x: details.localPosition.dx,
        y: details.localPosition.dy,
      );
      _gestureHandler.handleLongPress(screenPoint);
    } catch (e, stackTrace) {
      logger.e('Error handling long press', error: e, stackTrace: stackTrace);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    try {
      if (_isDragging) { // If we are in drag mode, handle drag
        final screenPoint = ScreenCoordinate(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        );
        _gestureHandler.handleDrag(screenPoint);
      }
    } catch (e, stackTrace) {
      logger.e('Error handling drag update', error: e, stackTrace: stackTrace);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    try {
      logger.i('Long press ended');
      if (_isDragging) {
        // If we are in drag mode and user released long press,
        // call endDrag anyway
        _gestureHandler.endDrag();
      }
    } catch (e, stackTrace) {
      logger.e('Error handling long press end', error: e, stackTrace: stackTrace);
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    return GestureDetector(
      onLongPressStart: _handleLongPress,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: () {
        logger.i('Long press cancelled');
        if (_isDragging) {
          _gestureHandler.endDrag();
        }
      },
      child: MapWidget(
        cameraOptions: MapConfig.defaultCameraOptions,
        styleUri: MapConfig.styleUri,
        onMapCreated: _onMapCreated,
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 10,
      child: BackButton(
        onPressed: () {
          logger.i('Navigating back from EarthMapPage');
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSearchToggleButton() {
    return Positioned(
      top: 40,
      left: 10,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(8),
        ),
        onPressed: () {
          setState(() {
            _showSearchBar = !_showSearchBar;
            if (!_showSearchBar) {
              _suggestions.clear();
            }
          });
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildClearAnnotationsButton() {
    return Positioned(
      top: 40,
      right: 10,
      child: ElevatedButton(
        onPressed: () async {
          logger.i('Clear button pressed - clearing all annotations from Hive.');
          final box = await Hive.openBox<Map>('annotationsBox');
          await box.clear();
          await box.close();
          logger.i('Annotations cleared. Restart app or add new annotations.');
        },
        child: const Text('Clear Annotations'),
      ),
    );
  }

  Widget _buildClearImagesButton() {
    return Positioned(
      top: 90,
      right: 10,
      child: ElevatedButton(
        onPressed: () async {
          logger.i('Clear images button pressed - clearing images folder files.');
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory(p.join(appDir.path, 'images'));

          if (await imagesDir.exists()) {
            final files = imagesDir.listSync();
            for (var file in files) {
              if (file is File) {
                await file.delete();
              }
            }
            logger.i('All image files cleared from ${imagesDir.path}');
          } else {
            logger.i('Images directory does not exist, nothing to clear.');
          }
        },
        child: const Text('Clear Images'),
      ),
    );
  }

  Widget _buildDeleteImagesFolderButton() {
    return Positioned(
      top: 140,
      right: 10,
      child: ElevatedButton(
        onPressed: () async {
          logger.i('Delete images folder button pressed - deleting entire images folder.');
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory(p.join(appDir.path, 'images'));

          if (await imagesDir.exists()) {
            await imagesDir.delete(recursive: true);
            logger.i('Images directory deleted.');
          } else {
            logger.i('Images directory does not exist, nothing to delete.');
          }
        },
        child: const Text('Delete Images Folder'),
      ),
    );
  }

  Widget _buildAddressSearchWidget() {
    if (!_showSearchBar) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      left: 80,
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'Enter address',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final address = _addressController.text.trim();
                    if (address.isEmpty) {
                      return;
                    }

                    final parts = address.split(',');
                    final streetPart = parts.isNotEmpty ? parts[0].trim() : address;

                    final coords = await GeocodingService.fetchCoordinatesFromAddress(address);
                    if (coords != null) {
                      logger.i('Coordinates received: $coords');
                      final lat = coords['lat']!;
                      final lng = coords['lng']!;

                      final geometry = Point(coordinates: Position(lng, lat));

                      final bytes = await rootBundle.load('assets/icons/cross.png');
                      final imageData = bytes.buffer.asUint8List();

                      final annotationId = uuid.v4();
                      final annotation = Annotation(
                        id: annotationId,
                        title: streetPart,
                        iconName: "cross",
                        date: "",
                        note: "",
                        latitude: lat,
                        longitude: lng,
                        imagePath: null,
                      );
                      await _localRepo.addAnnotation(annotation);
                      logger.i('Searched annotation saved to Hive with id: $annotationId');

                      final mapAnnotation = await _annotationsManager.addAnnotation(
                        geometry,
                        image: imageData,
                        title: streetPart,
                        date: "",
                      );
                      logger.i('Annotation placed at searched location.');

                      _gestureHandler.registerAnnotationId(mapAnnotation.id, annotationId);

                      _mapboxMap.setCamera(
                        CameraOptions(
                          center: geometry,
                          zoom: 14.0,
                        ),
                      );
                    } else {
                      logger.w('No coordinates found for the given address.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No coordinates found for the given address.'))
                      );
                    }
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              width: 250,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () {
                      _addressController.text = s;
                      _suggestions.clear();
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(s),
                    ),
                  );
                }).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAnnotationMenu() {
    if (!_showAnnotationMenu || _annotationMenuAnnotation == null) return const SizedBox.shrink();

    return Positioned(
      left: _annotationMenuOffset.dx,
      top: _annotationMenuOffset.dy,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (_isDragging) {
              // User clicked "Lock"
              _gestureHandler.hideTrashCanAndStopDragging();
              _isDragging = false;
              // Keep menu visible, now button says "Move"
            } else {
              // User clicked "Move"
              _gestureHandler.startDraggingSelectedAnnotation();
              _isDragging = true;
              // Trash can is shown by startDraggingSelectedAnnotation
            }
          });
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Text(_annotationButtonText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isError
          ? _buildErrorWidget()
          : Stack(
              children: [
                _buildMapWidget(),
                if (_isMapReady) _buildBackButton(),
                if (_isMapReady) _buildSearchToggleButton(),
                if (_isMapReady) _buildClearAnnotationsButton(),
                if (_isMapReady) _buildClearImagesButton(),
                if (_isMapReady) _buildDeleteImagesFolderButton(),
                if (_isMapReady) _buildAddressSearchWidget(),
                if (_isMapReady) _buildAnnotationMenu(),
              ],
            ),
    );
  }
}