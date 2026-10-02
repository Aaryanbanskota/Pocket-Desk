import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../data/models/weather_info.dart';

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherInfo>>((ref) {
  return WeatherNotifier();
});

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherInfo>> {
  WeatherNotifier() : super(const AsyncValue.loading()) {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();
    try {
      double? lat;
      double? lon;
      String cityName = 'Current Location';
      double? accuracy;

      // 1. Try IP Geolocation first (works on Linux desktop, laptops, and systems without hardware GPS)
      try {
        final ipRes = await http
            .get(Uri.parse('http://ip-api.com/json'))
            .timeout(const Duration(seconds: 4));
        if (ipRes.statusCode == 200) {
          final Map<String, dynamic> ipData =
              jsonDecode(ipRes.body) as Map<String, dynamic>;
          if (ipData['status'] == 'success') {
            lat = (ipData['lat'] as num?)?.toDouble();
            lon = (ipData['lon'] as num?)?.toDouble();
            final city = ipData['city']?.toString() ?? '';
            final country = ipData['country']?.toString() ?? '';
            if (city.isNotEmpty) {
              cityName = country.isNotEmpty ? '$city, $country' : city;
            }
          }
        }
      } catch (_) {}

      // 2. Fallback to Geolocator for mobile hardware GPS if IP Geolocation didn't return coords
      if ((lat == null || lon == null) && !Platform.isLinux) {
        try {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            if (await Geolocator.isLocationServiceEnabled()) {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium,
                  timeLimit: Duration(seconds: 5),
                ),
              );
              lat = position.latitude;
              lon = position.longitude;
              accuracy = position.accuracy;
            }
          }
        } catch (_) {}
      }

      if (lat == null || lon == null) {
        throw Exception('Location is unavailable. Please check your internet connection.');
      }

      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current':
            'temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Weather service returned ${response.statusCode}.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      state = AsyncValue.data(
        WeatherInfo.fromJson(
          data,
          cityName,
          accuracyMeters: accuracy,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> openLocationSettings() async {
    if (Platform.isLinux) {
      fetchWeather();
      return;
    }
    if (!await Geolocator.openLocationSettings()) {
      throw Exception('Could not open Location settings.');
    }
  }

  Future<void> openAppSettings() async {
    if (Platform.isLinux) {
      fetchWeather();
      return;
    }
    if (!await Geolocator.openAppSettings()) {
      throw Exception('Could not open app permission settings.');
    }
  }
}
