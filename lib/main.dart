import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_mvp_project/src/app.dart';
import 'package:map_mvp_project/services/error_handler.dart';
import 'package:map_mvp_project/services/orientation_util.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:map_mvp_project/services/geocoding_service.dart'; // Import the geocoding service

void main() {
  // Setup error handling for Flutter framework and async errors
  setupErrorHandling();

  // Start app initialization with error handling
  runAppWithErrorHandling(_initializeApp);

  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

// App initialization function (private)
void _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Initializing app, locking orientation, and initializing Hive.');

  await Hive.initFlutter();

  await lockOrientation().catchError((error, stackTrace) {
    logger.e('Failed to set orientation', error: error, stackTrace: stackTrace);
  });

  // Initialize geocoding service
  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  if (ACCESS_TOKEN.isEmpty) {
    logger.e('No ACCESS_TOKEN provided. Please run with --dart-define=ACCESS_TOKEN=your_token');
  }
  final geocodingService = GeocodingService(accessToken: ACCESS_TOKEN);

  // Optional test call (just a hardcoded test):
  try {
    final coords = await geocodingService.fetchCoordinatesFromAddress("1600 Amphitheatre Parkway, Mountain View, CA");
    logger.i('Test geocoding result: $coords');
  } catch (e, stackTrace) {
    logger.e('Geocoding test error', error: e, stackTrace: stackTrace);
  }

  _runAppSafely();
}

// Function to safely run the app with error handling (private)
void _runAppSafely() {
  try {
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    logger.e('Error while running the app', error: e, stackTrace: stackTrace);
  }
}