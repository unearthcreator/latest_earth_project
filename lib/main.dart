import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/app.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/services/orientation_util.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:map_mvp_project/services/geocoding_service.dart'; // Ensure this import is present

void main() {
  setupErrorHandling();
  runAppWithErrorHandling(_initializeApp);

  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

void _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Initializing app, locking orientation, and initializing Hive.');

  await Hive.initFlutter();

  await lockOrientation().catchError((error, stackTrace) {
    logger.e('Failed to set orientation', error: error, stackTrace: stackTrace);
  });

  // Remove this line if constructor doesn't accept arguments
  // final geocodingService = GeocodingService(); 

  // Optional test call (just a hardcoded test):
  try {
    final coords = await GeocodingService.fetchCoordinatesFromAddress("1600 Amphitheatre Parkway, Mountain View, CA");
    logger.i('Test geocoding result: $coords');
  } catch (e, stackTrace) {
    logger.e('Test geocoding failed', error: e, stackTrace: stackTrace);
  }

  _runAppSafely();
}

void _runAppSafely() {
  try {
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    logger.e('Error while running the app', error: e, stackTrace: stackTrace);
  }
}