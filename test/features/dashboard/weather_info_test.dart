import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/dashboard/data/models/weather_info.dart';

void main() {
  test('parses current Open-Meteo readings and device accuracy', () {
    final weather = WeatherInfo.fromJson(
      {
        'current': {
          'temperature_2m': 19.5,
          'apparent_temperature': 18.0,
          'relative_humidity_2m': 62,
          'weather_code': 3,
          'wind_speed_10m': 8.4,
          'time': '2026-09-28T00:15',
        },
      },
      'Current location',
      accuracyMeters: 24.8,
    );

    expect(weather.temperature, 19.5);
    expect(weather.apparentTemperature, 18);
    expect(weather.humidity, 62);
    expect(weather.weatherCode, 3);
    expect(weather.windSpeed, 8.4);
    expect(weather.accuracyMeters, 24.8);
    expect(weather.description, 'Partly Cloudy');
  });

  test('rejects missing current weather instead of reporting zero readings',
      () {
    expect(
      () => WeatherInfo.fromJson(
        {'current': <String, dynamic>{}},
        'Current location',
      ),
      throwsFormatException,
    );
  });
}
