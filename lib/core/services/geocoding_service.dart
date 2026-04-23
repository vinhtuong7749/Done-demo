import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for address suggestions using OpenStreetMap Nominatim
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Search for address suggestions based on a query string
  Future<List<MapSuggestion>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      String finalQuery = query;
      if (!finalQuery.toLowerCase().contains('đà nẵng') && !finalQuery.toLowerCase().contains('da nang')) {
        finalQuery = '$query, Đà Nẵng';
      }
      final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(finalQuery)}&format=json&limit=5&addressdetails=1&accept-language=vi&countrycodes=vn');
      
      debugPrint('🗺️ [GEOCODING] GET $url');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Extract house number prefix from original query (e.g. "50", "95A")
        String? houseNumber;
        final match = RegExp(r'^(\d+[a-zA-Z]?)\s+.*$').firstMatch(query.trim());
        if (match != null) {
          houseNumber = match.group(1);
        }

        return data.map((item) {
          final suggestion = MapSuggestion.fromJson(item);
          
          // Inject house number if the user typed it but Nominatim omitted it
          if (houseNumber != null && houseNumber.isNotEmpty) {
            final parts = suggestion.displayName.split(',').map((e) => e.trim()).toList();
            // If the first part isn't already the house number
            if (parts.isNotEmpty && !parts[0].startsWith(houseNumber)) {
              return MapSuggestion(
                displayName: '$houseNumber, ${suggestion.displayName}',
                lat: suggestion.lat,
                lon: suggestion.lon,
              );
            }
          }
          
          return suggestion;
        }).toList();
      } else {
        debugPrint('❌ [GEOCODING] Error status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [GEOCODING] Error: $e');
      return [];
    }
  }
}

class MapSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  MapSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory MapSuggestion.fromJson(Map<String, dynamic> json) {
    return MapSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat'] ?? '0') ?? 0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0,
    );
  }

  String get mainText {
    if (displayName.isEmpty) return '';
    final parts = displayName.split(',').map((e) => e.trim()).toList();
    if (parts.length > 1) {
      // If the first part is a short number or contains only alphanumeric like '50A', combine it with street
      if (RegExp(r'^[\d]+[a-zA-Z]?$').hasMatch(parts[0])) {
         return '${parts[0]} ${parts[1]}';
      }
      return parts.first;
    }
    return displayName;
  }

  String get secondaryText {
    if (displayName.isEmpty) return '';
    final parts = displayName.split(',').map((e) => e.trim()).toList();
    if (parts.length > 1) {
      int skipCount = RegExp(r'^[\d]+[a-zA-Z]?$').hasMatch(parts[0]) ? 2 : 1;
      final secondaryParts = parts.skip(skipCount).where((e) {
        final lower = e.toLowerCase();
        return lower != 'việt nam' && lower != 'vietnam' && !RegExp(r'^\d{5,6}$').hasMatch(e);
      });
      return secondaryParts.join(', ');
    }
    return '';
  }

  @override
  String toString() => 'MapSuggestion($displayName, $lat, $lon)';
}
