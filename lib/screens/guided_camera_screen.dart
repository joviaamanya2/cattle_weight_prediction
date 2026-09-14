import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../services/prediction_api.dart';
import '../theme/app_theme.dart';

/// A framing status derived from the live object-detection feed.
///
/// The ML Kit base detector finds the most prominent object's bounding box
/// without knowing what it is — it has no "cow" label — so this screen never
/// asks the model to name the subject. It only compares the box's size,
/// position and shape against the frame to judge distance, centering and
/// side-on orientation.
enum _FrameStatus {
  noSubject,
  wayTooFar,
  tooFar,
  tooClose,
  wayTooClose,
  offCenter,
  needsSideProfile,
  ready,
}

/// How long the framing must stay in [_FrameStatus.ready] before the app
/// snaps the photo on its own.
const Duration _autoCaptureHold = Duration(milliseconds: 900);

/// Live camera screen that gives real-time framing feedback (distance,
/// centering, side-on orientation) before the farmer takes the cattle photo.
///
/// Pops with an [XFile] on successful capture, or `null` if the user backs
/// out.
class GuidedCameraScreen extends StatefulWidget {
  const GuidedCameraScreen({super.key});

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  ObjectDetector? _detector;

  bool _isDetecting = false;
  bool _isCapturing = false;
  bool _isValidatingCapture = false;
  bool _isValidationSlow = false;
  String? _initError;
  String? _rejectionMessage;

  _FrameStatus _status = _FrameStatus.noSubject;
  Timer? _autoCaptureTimer;
  Timer? _slowValidationTimer;
  Timer? _rejectionMessageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        // We only need the bounding box of the salient subject, not a label
        // — the base model's five coarse categories don't include animals.
        classifyObjects: false,
        multipleObjects: false,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera available on device.');
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream(_onCameraFrame);

      setState(() {
        _controller = controller;
        _initError = null;
      });
    } catch (e) {
      debugPrint('Guided camera init error: $e');
      if (!mounted) return;
      setState(() {
        _initError = 'Could not start the camera. Check that camera '
            'permission is allowed for this app, then try again.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ------------------------------------------------------------
  // FRAME ANALYSIS
  // ------------------------------------------------------------

  void _onCameraFrame(CameraImage image) {
    if (_isDetecting || _detector == null || _controller == null) return;
    _isDetecting = true;

    final inputImage = _toInputImage(image, _controller!.description);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    _detector!.processImage(inputImage).then((objects) {
      _isDetecting = false;
      if (!mounted) return;

      final frameSize = Size(image.width.toDouble(), image.height.toDouble());
      final box = objects.isEmpty ? null : objects.first.boundingBox;
      final status = _evaluate(box, frameSize);

      if (status != _status) {
        setState(() => _status = status);
        _updateAutoCapture(status);
      }
    }).catchError((Object e) {
      _isDetecting = false;
      debugPrint('Object detection error: $e');
    });
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final format =
        Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    final buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Turns a detected bounding box into a framing verdict.
  ///
  /// All thresholds are relative to the raw frame size, so they hold
  /// regardless of resolution or how the preview is scaled on screen.
  _FrameStatus _evaluate(Rect? box, Size frameSize) {
    if (box == null || frameSize.width == 0 || frameSize.height == 0) {
      return _FrameStatus.noSubject;
    }

    final frameArea = frameSize.width * frameSize.height;
    final boxArea = box.width * box.height;
    final areaRatio = boxArea / frameArea;

    if (areaRatio < 0.04) return _FrameStatus.wayTooFar;
    if (areaRatio < 0.12) return _FrameStatus.tooFar;
    if (areaRatio > 0.8) return _FrameStatus.wayTooClose;
    if (areaRatio > 0.65) return _FrameStatus.tooClose;

    final frameCenter = Offset(frameSize.width / 2, frameSize.height / 2);
    final boxCenter = box.center;
    final dx = (boxCenter.dx - frameCenter.dx).abs() / frameSize.width;
    final dy = (boxCenter.dy - frameCenter.dy).abs() / frameSize.height;

    if (dx > 0.18 || dy > 0.2) return _FrameStatus.offCenter;

    // A cow shot side-on reads as a box clearly wider than it is tall. One
    // facing the camera, or cut off, reads closer to square.
    final aspect = box.width / box.height;
    if (aspect < 1.15) return _FrameStatus.needsSideProfile;

    return _FrameStatus.ready;
  }

  // ------------------------------------------------------------
  // AUTO-CAPTURE
  // ------------------------------------------------------------

  /// Starts (or cancels) the hold-still countdown as framing becomes ready
  /// or stops being ready. A manual tap on the shutter still works at any
  /// time regardless of this timer.
  void _updateAutoCapture(_FrameStatus status) {
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;

    if (status != _FrameStatus.ready) return;

    _autoCaptureTimer = Timer(_autoCaptureHold, () {
      if (mounted && _status == _FrameStatus.ready && !_isCapturing) {
        _capture();
      }
    });
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _isCapturing) return;

    _rejectionMessageTimer?.cancel();

    setState(() {
      _isCapturing = true;
      _isValidatingCapture = true;
      _isValidationSlow = false;
      _rejectionMessage = null;
    });

    // The validation call hits a live backend that can be slow to wake up
    // (e.g. a sleeping free-tier host), so let the user know it hasn't
    // stalled if it's taking a while instead of leaving them guessing.
    _slowValidationTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _isValidationSlow = true);
    });

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      final file = await controller.takePicture();
      final image = XFile(file.path);
      final isCattle = await PredictionApiService.instance
          .validateCattleImage(image: image);

      if (!isCattle) {
        await File(file.path).delete();
        if (!mounted) return;

        if (!controller.value.isStreamingImages) {
          await controller.startImageStream(_onCameraFrame);
        }
        if (!mounted) return;

        setState(() {
          _isCapturing = false;
          _isValidatingCapture = false;
          // Force a fresh read next frame — otherwise a still-matching
          // "ready" status never changes, so auto-capture (which only
          // re-arms on a status change) would silently never fire again.
          _status = _FrameStatus.noSubject;
        });
        _showRejectionMessage(
          "That doesn't look like a cow, bull or calf. Reframe the "
          'animal and try again.',
        );
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pop(image);
    } catch (e) {
      debugPrint('Guided capture error: $e');
      if (!mounted) return;

      if (!controller.value.isStreamingImages) {
        await controller.startImageStream(_onCameraFrame);
      }
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _isValidatingCapture = false;
        _status = _FrameStatus.noSubject;
      });
      _showRejectionMessage(
        e is PredictionApiException
            ? e.userMessage
            : 'Could not validate the photo. Please try again.',
      );
    } finally {
      _slowValidationTimer?.cancel();
    }
  }

  void _showRejectionMessage(String message) {
    _rejectionMessageTimer?.cancel();
    setState(() => _rejectionMessage = message);
    _rejectionMessageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _rejectionMessage = null);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCaptureTimer?.cancel();
    _slowValidationTimer?.cancel();
    _rejectionMessageTimer?.cancel();

    final controller = _controller;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }

    _detector?.close();
    super.dispose();
  }

  // ------------------------------------------------------------
  // STATUS PRESENTATION
  // ------------------------------------------------------------

  String get _statusMessage {
    if (_rejectionMessage != null) return _rejectionMessage!;

    if (_isValidatingCapture) {
      return _isValidationSlow
          ? 'Still checking — this can take longer on a slow connection...'
          : 'Checking that this is cattle...';
    }

    switch (_status) {
      case _FrameStatus.noSubject:
        return 'Point the camera at the cow';
      case _FrameStatus.wayTooFar:
        return 'Go a lot closer';
      case _FrameStatus.tooFar:
        return 'Move in a little closer';
      case _FrameStatus.tooClose:
        return 'Step back a little';
      case _FrameStatus.wayTooClose:
        return "You're too close — step back";
      case _FrameStatus.offCenter:
        return 'Center the cow in the frame';
      case _FrameStatus.needsSideProfile:
        return "Turn so the cow's full side is visible";
      case _FrameStatus.ready:
        return 'Perfect distance — hold still, capturing...';
    }
  }

  IconData get _statusIcon {
    if (_rejectionMessage != null) return Icons.error_outline_rounded;
    if (_isValidatingCapture) return Icons.hourglass_top_rounded;

    switch (_status) {
      case _FrameStatus.noSubject:
        return Icons.search_rounded;
      case _FrameStatus.wayTooFar:
      case _FrameStatus.tooFar:
        return Icons.arrow_upward_rounded;
      case _FrameStatus.tooClose:
      case _FrameStatus.wayTooClose:
        return Icons.arrow_downward_rounded;
      case _FrameStatus.offCenter:
        return Icons.center_focus_weak_rounded;
      case _FrameStatus.needsSideProfile:
        return Icons.rotate_90_degrees_ccw_rounded;
      case _FrameStatus.ready:
        return Icons.check_circle_rounded;
    }
  }

  bool get _isReady => _status == _FrameStatus.ready;

  Color get _statusColor {
    if (_rejectionMessage != null) return AppColors.danger;
    if (_isValidatingCapture) return AppColors.primary;
    return _isReady ? AppColors.success : AppColors.warning;
  }

  Color get _statusSoftColor {
    if (_rejectionMessage != null) return AppColors.dangerSoft;
    if (_isValidatingCapture) return AppColors.primarySoft;
    return _isReady ? AppColors.successSoft : AppColors.warningSoft;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initError != null
            ? _buildError(_initError!)
            : _controller == null || !_controller!.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildCameraUi(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: _initCamera,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUi() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: CameraPreview(_controller!),
        ),

        // Guide frame: a fixed target zone. Real detection drives the text
        // above/below it, not the box itself, so this never has to be
        // reprojected from image space into preview space.
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.78,
            heightFactor: 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _statusColor, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),

        // Top status banner, plus a persistent one-line explainer of how
        // auto-capture works — first-time users otherwise have no way to
        // know a green box means "hold still, it captures itself".
        Positioned(
          top: AppSpacing.lg,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: _statusSoftColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              _statusMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_rejectionMessage == null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Frame the whole cow from the side — it captures '
                    'automatically once the box turns green.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom shutter control.
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.section,
          child: Center(
            child: GestureDetector(
              onTap: _isCapturing ? null : _capture,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _isReady ? AppColors.success : Colors.black38,
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
