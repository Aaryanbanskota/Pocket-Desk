import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/feed/presentation/instant_camera_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InstantCameraScreen displays camera not found error on shutter tap when no camera hardware', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      (methodCall) async {
        if (methodCall.method == 'availableCameras') {
          return <dynamic>[];
        }
        return null;
      },
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? createdPath;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstantCameraScreen(
            onInstantCreated: (path, overlay) async {
              createdPath = path;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Viewfinder shows camera not found message
    expect(find.textContaining('Camera not found'), findsWidgets);

    // Tap large shutter button (the circular shutter container)
    final whiteCircle = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.constraints?.maxWidth == 60 || (w.decoration as BoxDecoration).color == Colors.white));
    expect(whiteCircle, findsWidgets);

    await tester.tap(whiteCircle.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify SnackBar appears with exact requirement message
    expect(
      find.text('Camera not found. There was no camera to click a photo on this device.'),
      findsOneWidget,
    );
    expect(createdPath, isNull);
  });
}
