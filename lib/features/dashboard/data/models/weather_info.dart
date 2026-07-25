class WeatherInfo {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final String description;
  final String cityName;

  WeatherInfo({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
    required this.cityName,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json, String cityName) {
    final current = (json['current_weather'] ?? json['current']) as Map<String, dynamic>;
    final temp = ((current['temperature'] ?? current['temperature_2m'] ?? 0.0) as num).toDouble();
    final wind = ((current['windspeed'] ?? current['wind_speed_10m'] ?? 0.0) as num).toDouble();
    final code = ((current['weathercode'] ?? current['weather_code'] ?? 0) as num).toInt();

    return WeatherInfo(
      temperature: temp,
      windSpeed: wind,
      weatherCode: code,
      description: _getWeatherDescription(code),
      cityName: cityName,
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
