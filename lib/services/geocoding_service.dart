import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_mvp_project/services/error_handler.dart';

class GeocodingService {
  final String accessToken;

  GeocodingService({required this.accessToken});

  Future<Map<String, dynamic>?> fetchCoordinatesFromAddress(String address) async {
    // Encode the address to be used in a URL
    final encodedAddress = Uri.encodeComponent(address);

    // This is an example using Mapbox Geocoding API:
    // See: https://docs.mapbox.com/api/search/geocoding/
    // endpoint: https://api.mapbox.com/geocoding/v5/mapbox.places/{query}.json
    final url = Uri.parse('https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedAddress.json?access_token=$accessToken&limit=1');

    logger.i('Geocoding request: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      logger.i('Geocoding response: $jsonData');

      // Extract coordinates if available
      if (jsonData['features'] != null && jsonData['features'].isNotEmpty) {
        final feature = jsonData['features'][0];
        if (feature['center'] != null && feature['center'].length == 2) {
          final double lng = feature['center'][0];
          final double lat = feature['center'][1];
          logger.i('Coordinates found: lat=$lat, lng=$lng');
          return {'lat': lat, 'lng': lng};
        } else {
          logger.w('No coordinates found in the feature');
          return null;
        }
      } else {
        logger.w('No features returned for the given address');
        return null;
      }
    } else {
      logger.e('Geocoding failed with status: ${response.statusCode}, body: ${response.body}');
      return null;
    }
  }
}