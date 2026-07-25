import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../data/models/weather_info.dart';

final weatherProvider = StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherInfo>>((ref) {
  return WeatherNotifier();
});

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherInfo>> {
  WeatherNotifier() : super(const AsyncValue.loading()) {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();
    try {
      // 1. Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Fallback if location service is disabled
        return _fetchFallbackWeather('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fetchFallbackWeather('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fetchFallbackWeather('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // 2. Fetch from Open-Meteo
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Reverse geocoding fallback: just say "Local Weather" or fetch city if wanted.
        // To avoid importing another dependency, we'll label it by coordinates roughly or "My Location".
        final info = WeatherInfo.fromJson(data, 'My Location');
        state = AsyncValue.data(info);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Try to fetch fallback weather (Kathmandu / Default location) so we still show something correct
      _fetchFallbackWeather('Failed to get location or connection error. Showing default Kathmandu weather.');
    }
  }

  Future<void> _fetchFallbackWeather(String reason) async {
    try {
      // Fallback coordinates for Kathmandu
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=27.7172&longitude=85.3240&current_weather=true',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final info = WeatherInfo.fromJson(data, 'Kathmandu');
        state = AsyncValue.data(info);
      } else {
        throw Exception('Failed to load fallback');
      }
    } catch (e, st) {
      state = AsyncValue.error(reason, st);
    }
  }
}
