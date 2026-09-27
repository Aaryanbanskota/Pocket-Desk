class WeatherInfo {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final String description;
  final String cityName;
  final double? apparentTemperature;
  final int? humidity;
  final DateTime? observedAt;
  final double? accuracyMeters;

  WeatherInfo({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    required this.cityName,
    this.apparentTemperature,
    this.humidity,
    this.observedAt,
    this.accuracyMeters,
  });

  factory WeatherInfo.fromJson(
    Map<String, dynamic> json,
    String cityName, {
    double? accuracyMeters,
  }) {
    final current = Map<String, dynamic>.from(
      (json['current'] ?? json['current_weather']) as Map,
    );
    final temperature = current['temperature_2m'] ?? current['temperature'];
    final wind = current['wind_speed_10m'] ?? current['windspeed'];
    final code = current['weather_code'] ?? current['weathercode'];
    if (temperature is! num || wind is! num || code is! num) {
      throw const FormatException('Weather response is missing current data.');
    }
    final apparent = current['apparent_temperature'] as num?;
    final humidity = current['relative_humidity_2m'] as num?;
    final observedAt = DateTime.tryParse(current['time']?.toString() ?? '');

    return WeatherInfo(
      temperature: temperature.toDouble(),
      windSpeed: wind.toDouble(),
      weatherCode: code.toInt(),
      description: _getWeatherDescription(code.toInt()),
      cityName: cityName,
      apparentTemperature: apparent?.toDouble(),
      humidity: humidity?.toInt(),
      observedAt: observedAt,
      accuracyMeters: accuracyMeters,
    );
  }

  static String _getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
      case 2:
      case 3:
        return 'Partly Cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 71:
      case 73:
      case 75:
        return 'Snowy';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }
}
