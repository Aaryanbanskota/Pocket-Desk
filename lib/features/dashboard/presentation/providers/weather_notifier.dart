import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
      if (Platform.isLinux) {
        throw UnsupportedError(
          'Automatic location is not available on Linux in this app build.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          permission == LocationPermission.deniedForever
              ? 'Location permission is blocked. Enable it in app settings.'
              : 'Location permission is needed for local weather.',
        );
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Location Services are off. Turn them on to get local weather.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'current':
            'temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Weather service returned ${response.statusCode}.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      state = AsyncValue.data(
        WeatherInfo.fromJson(
          data,
          'Current location',
          accuracyMeters: position.accuracy,
        ),
      );
    } on MissingPluginException {
      state = AsyncValue.error(
        UnsupportedError(
          'The location service is unavailable in this app build.',
        ),
        StackTrace.current,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> openLocationSettings() async {
    if (Platform.isLinux) {
      throw UnsupportedError(
        'Location settings are not available on Linux in this app build.',
      );
    }
    if (!await Geolocator.openLocationSettings()) {
      throw Exception('Could not open Location settings.');
    }
  }

  Future<void> openAppSettings() async {
    if (Platform.isLinux) {
      throw UnsupportedError(
        'App permission settings are not available on Linux.',
      );
    }
    if (!await Geolocator.openAppSettings()) {
      throw Exception('Could not open app permission settings.');
    }
  }
}
