import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_mvp_project/services/error_handler.dart';

class GeocodingService {
  static const String accessToken = "pk.eyJ1IjoidW5lYXJ0aGNyZWF0b3IiLCJhIjoiY20yam4yODlrMDVwbzJrcjE5cW9vcDJmbiJ9.L2tmRAkt0jKLd8-fWaMWfA"; // Replace with your actual token

  static Future<Map<String, dynamic>?> fetchCoordinatesFromAddress(String address) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json'
      '?access_token=$accessToken'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      logger.i('Geocoding response: $data');

      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        final center = feature['center']; // [lng, lat]
        final lng = center[0];
        final lat = center[1];
        logger.i('Coordinates found: lat=$lat, lng=$lng');
        return {'lat': lat, 'lng': lng};
      } else {
        logger.w('No features found for given address.');
        return null;
      }
    } else {
      logger.e('Failed to fetch geocoding data: ${response.statusCode}');
      return null;
    }
  }
}