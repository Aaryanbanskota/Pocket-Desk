import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design_system/app_colors.dart';
import '../data/feed_repository.dart';

class InstantCameraScreen extends StatefulWidget {
  final String title;
  final String? initialPath;
  final Future<void> Function(String imagePath, String? textOverlay) onInstantCreated;

  const InstantCameraScreen({
    super.key,
    this.title = 'New Instant',
    this.initialPath,
    required this.onInstantCreated,
  });

  static Future<void> open(
    BuildContext context, {
    String title = 'New Instant',
    required Future<void> Function(String imagePath, String? textOverlay) onInstantCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      barrierColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => InstantCameraScreen(
        title: title,
        onInstantCreated: onInstantCreated,
      ),
    );
  }

  @override
  State<InstantCameraScreen> createState() => _InstantCameraScreenState();
}

class _InstantCameraScreenState extends State<InstantCameraScreen> {
  final _textCtrl = TextEditingController();
  Offset _textOffset = const Offset(60, 220);
  String _imagePath = '';
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialPath ?? '';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        await _setupController(_availableCameras[_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _cameraError = 'Camera not found.\nThere was no camera detected on this device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera not found.\nThere was no camera detected on this device.';
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = 'Failed to start camera: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      if (mounted) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (kIsWeb || Platform.isLinux) return;
    if (_availableCameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    setState(() => _isCameraInitialized = false);
    await _setupController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _captureOrPost() async {
    if (_isCapturing) return;

    String finalPath = _imagePath;

    if (finalPath.isEmpty) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        setState(() => _isCapturing = true);
        try {
          final XFile photo = await _cameraController!.takePicture();
          if (mounted) {
            setState(() {
              _imagePath = photo.path;
              _isCapturing = false;
            });
          }
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to capture photo: $e')),
            );
          }
          setState(() => _isCapturing = false);
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera not found. There was no camera to click a photo on this device.'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final overlay = _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim();
    final savedPath = await FeedRepository.persistMediaFile(finalPath, subDir: 'instants');
    await widget.onInstantCreated(savedPath, overlay);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLinuxOrWeb = kIsWeb || Platform.isLinux;
    final canSwitchCamera = !isLinuxOrWeb && _availableCameras.length > 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      color: const Color(0xFF0D0E11),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.image, color: Colors.white, size: 22),
                    tooltip: 'Choose from gallery',
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() {
                          _imagePath = picked.path;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Main Viewfinder Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo Preview or Camera Stream
                      if (_imagePath.isNotEmpty && File(_imagePath).existsSync())
                        Image.file(File(_imagePath), fit: BoxFit.cover)
                      else if (_isCameraInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        Container(
                          color: const Color(0xFF1E222A),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.08),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white70,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _cameraError ?? 'Initializing Camera Stream…',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (_cameraError != null) ...[
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(LucideIcons.image, size: 16),
                                    label: const Text('Choose from Gallery'),
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(source: ImageSource.gallery);
                                      if (picked != null && mounted) {
                                        setState(() {
                                          _imagePath = picked.path;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // Draggable Text Overlay
                      Positioned(
                        left: _textOffset.dx,
                        top: _textOffset.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _textOffset += details.delta;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _textCtrl.text.isEmpty ? 'Tap to add overlay text' : _textCtrl.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Text Input Field on Top
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: TextField(
                          controller: _textCtrl,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Type overlay text…',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      // Retake button if photo captured
                      if (_imagePath.isNotEmpty)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => setState(() => _imagePath = ''),
                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                            label: const Text('Retake'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Shutter Controls
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash toggle
                  GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isFlashOn ? Colors.amber : const Color(0xFF1E222A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
                        color: _isFlashOn ? Colors.black : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  // Large Shutter Button
                  GestureDetector(
                    onTap: _captureOrPost,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _imagePath.isNotEmpty ? AppColors.accentOrange : Colors.white.withValues(alpha: 0.6),
                          width: 5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isCapturing
                                ? Colors.amber
                                : (_imagePath.isNotEmpty ? AppColors.accentOrange : Colors.white),
                            shape: BoxShape.circle,
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                                )
                              : (_imagePath.isNotEmpty
                                  ? const Icon(LucideIcons.check, color: Colors.white, size: 30)
                                  : null),
                        ),
                      ),
                    ),
                  ),

                  // Switch camera
                  GestureDetector(
                    onTap: canSwitchCamera ? _switchCamera : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: canSwitchCamera ? const Color(0xFF1E222A) : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.switchCamera,
                        color: canSwitchCamera ? Colors.white : Colors.white38,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
