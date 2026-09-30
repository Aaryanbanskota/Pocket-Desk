import 'package:flutter/material.dart';
import 'weather_widget.dart';
import 'progress_storage_widget.dart';

class SwipeableWeatherWidget extends StatefulWidget {
  const SwipeableWeatherWidget({super.key});

  @override
  State<SwipeableWeatherWidget> createState() => _SwipeableWeatherWidgetState();
}

class _SwipeableWeatherWidgetState extends State<SwipeableWeatherWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
            },
            children: const [
              WeatherWidget(),
              ProgressStorageWidget(),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _currentPage == 0 ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == 0
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _currentPage == 1 ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == 1
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
