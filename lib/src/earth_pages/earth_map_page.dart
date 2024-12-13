import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:map_mvp_project/repositories/local_annotations_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/src/earth_pages/annotations/map_annotations_manager.dart';
import 'package:map_mvp_project/src/earth_pages/gestures/map_gesture_handler.dart';
import 'package:map_mvp_project/src/earth_pages/utils/map_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:map_mvp_project/services/geocoding_service.dart';

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

  @override
  void initState() {
    super.initState();
    logger.i('Initializing EarthMapPage');

    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _gestureHandler.dispose();
    _addressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAddressChanged() {
    // Debounce to reduce API calls
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
      if (_gestureHandler.isDragging) {
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
      _gestureHandler.endDrag();
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
        _gestureHandler.endDrag();
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
      left: 60,
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

    final double containerWidth = MediaQuery.of(context).size.width * 0.5;
    final double containerLeft = (MediaQuery.of(context).size.width - containerWidth) / 2;

    return Positioned(
      top: 200,
      left: containerLeft,
      width: containerWidth,
      child: Column(
        children: [
          Container(
            color: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'Enter address',
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
                    final coords = await GeocodingService.fetchCoordinatesFromAddress(address);
                    if (coords != null) {
                      logger.i('Coordinates received: $coords');
                      final lat = coords['lat']!;
                      final lng = coords['lng']!;

                      final geometry = Point(coordinates: Position(lng, lat));

                      await _annotationsManager.addAnnotation(
                        geometry,
                        title: "Searched Place",
                        date: "",
                      );
                      logger.i('Annotation placed at searched location.');

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
          // Suggestion list
          if (_suggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () {
                      _addressController.text = s;
                      _suggestions.clear();
                      setState(() {}); // to refresh UI

                      // Optionally, directly search after suggestion pick:
                      // Similar to pressing "Search"
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
              ],
            ),
    );
  }
}