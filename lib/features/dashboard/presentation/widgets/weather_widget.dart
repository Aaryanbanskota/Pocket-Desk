import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/weather_notifier.dart';

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: weatherState.when(
        data: (weather) {
          return Row(
            children: [
              _buildWeatherIcon(weather.weatherCode),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.cityName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (weather.accuracyMeters != null &&
                        weather.accuracyMeters! > 0)
                      Text(
                        'GPS accuracy ±${weather.accuracyMeters!.round()} m',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (weather.observedAt != null)
                      Text(
                        'Updated ${TimeOfDay.fromDateTime(weather.observedAt!.toLocal()).format(context)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (weather.apparentTemperature != null)
                    Text(
                      'Feels ${weather.apparentTemperature!.toStringAsFixed(0)}°',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (weather.humidity != null)
                    Text(
                      'Humidity ${weather.humidity}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, _) => Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                err.toString().replaceFirst('Exception: ', ''),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () =>
                  ref.read(weatherProvider.notifier).fetchWeather(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(int code) {
    IconData icon;
    Color color;

    switch (code) {
      case 0:
        icon = Icons.wb_sunny_rounded;
        color = Colors.orange;
        break;
      case 1:
      case 2:
      case 3:
        icon = Icons.wb_cloudy_rounded;
        color = Colors.blueGrey;
        break;
      case 45:
      case 48:
        icon = Icons.cloud_queue_rounded;
        color = Colors.grey;
        break;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        icon = Icons.umbrella_rounded;
        color = Colors.blue;
        break;
      case 71:
      case 73:
      case 75:
        icon = Icons.ac_unit_rounded;
        color = Colors.lightBlueAccent;
        break;
      case 95:
      case 96:
      case 99:
        icon = Icons.thunderstorm_rounded;
        color = Colors.deepPurple;
        break;
      default:
        icon = Icons.cloud_rounded;
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
