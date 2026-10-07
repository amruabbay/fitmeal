import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fit_meal/providers/language_provider.dart';
import 'package:fit_meal/config/app_strings.dart';
import 'package:fit_meal/utils/image_helper_stub.dart'
    if (dart.library.html) 'package:fit_meal/utils/image_helper_web.dart'
    if (dart.library.io) 'package:fit_meal/utils/image_helper_io.dart';

class CropScreen extends StatefulWidget {
  final XFile imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final GlobalKey _viewportKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  double _currentZoom = 1.0;
  int _rotationQuarter = 0; // 0, 1, 2, 3 representing 0, 90, 180, 270 degrees
  bool _isProcessing = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error reading image bytes: $e");
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarter = (_rotationQuarter + 1) % 4;
    });
    HapticFeedback.mediumImpact();
  }

  void _resetAll() {
    setState(() {
      _rotationQuarter = 0;
      _currentZoom = 1.0;
      _transformationController.value = Matrix4.identity();
    });
    HapticFeedback.lightImpact();
  }

  void _updateZoom(double scale) {
    setState(() {
      _currentZoom = scale;
      final Matrix4 matrix = Matrix4.identity()..scale(scale);
      
      // Preserve current translation offsets to make scaling feel anchored
      final double tx = _transformationController.value.entry(0, 3);
      final double ty = _transformationController.value.entry(1, 3);
      matrix.setEntry(0, 3, tx);
      matrix.setEntry(1, 3, ty);
      
      _transformationController.value = matrix;
    });
  }

  Future<void> _performCrop() async {
    if (_isProcessing) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false).locale;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      String path;
      if (kIsWeb) {
        final double viewportSize = 340.0;
        final double logicalCutoutSize = 240.0;
        
        final double scale = _transformationController.value.getMaxScaleOnAxis();
        final double tx = _transformationController.value.entry(0, 3);
        final double ty = _transformationController.value.entry(1, 3);

        final Uint8List croppedBytes = await cropImageWeb(
          imagePath: widget.imageFile.path,
          scale: scale,
          tx: tx,
          ty: ty,
          rotationQuarter: _rotationQuarter,
          viewportSize: viewportSize,
          cutoutSize: logicalCutoutSize,
        );

        final base64Str = base64Encode(croppedBytes);
        path = 'data:image/png;base64,$base64Str';
      } else {
        // Find the render boundary
        final RenderRepaintBoundary? boundary = 
            _viewportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        
        if (boundary == null) {
          throw Exception("Could not find repaint boundary.");
        }

        // Capture the viewport at a high pixel ratio for maximum quality
        final double pixelRatio = MediaQuery.of(context).devicePixelRatio.clamp(2.0, 3.0);
        final ui.Image viewportImage = await boundary.toImage(pixelRatio: pixelRatio);
        
        final int W = viewportImage.width;
        final int H = viewportImage.height;

        // Cutout size in logical pixels is 240. Scaled cutout size:
        final double logicalCutoutSize = 240.0;
        final double S = logicalCutoutSize * pixelRatio;
        
        // Calculate coordinates centered in the captured viewport pixels
        final double left = (W - S) / 2;
        final double top = (H - S) / 2;

        // Create a PictureRecorder to crop the viewportImage dynamically
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        
        // Translate canvas to extract the cutout area cleanly
        canvas.drawImage(
          viewportImage,
          Offset(-left, -top),
          Paint(),
        );

        final ui.Picture picture = recorder.endRecording();
        final ui.Image croppedImage = await picture.toImage(S.toInt(), S.toInt());
        
        final ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception("Failed to convert image to bytes.");
        
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_cropped_${DateTime.now().millisecondsSinceEpoch}.png';
        final localFile = File('${appDir.path}/$fileName');
        await localFile.writeAsBytes(pngBytes);
        path = localFile.path;
      }

      final XFile croppedXFile = XFile(
        path,
        mimeType: 'image/png',
        name: 'profile_cropped.png',
      );

      if (mounted) {
        Navigator.pop(context, croppedXFile);
      }
    } catch (e) {
      debugPrint("Error during image cropping: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('failed_crop', lang)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).locale;
    final double viewportSize = 340.0;
    final double logicalCutoutSize = 240.0;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Premium Dark Slate 900
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('crop_title', lang),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _performCrop,
                child: Text(
                  AppStrings.get('done', lang),
                  style: const TextStyle(
                    color: Color(0xFF10B981), // FM Green
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              
              // Viewport with Squircle Overlay
              Center(
                child: SizedBox(
                  width: viewportSize,
                  height: viewportSize,
                  child: Stack(
                    children: [
                      // Viewport capturing boundary
                      RepaintBoundary(
                        key: _viewportKey,
                        child: Container(
                          width: viewportSize,
                          height: viewportSize,
                          color: const Color(0xFF1E293B), // Slate 800 background
                          child: RotatedBox(
                            quarterTurns: _rotationQuarter,
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 0.5,
                              maxScale: 5.0,
                              onInteractionUpdate: (details) {
                                setState(() {
                                  _currentZoom = _transformationController.value.getMaxScaleOnAxis();
                                });
                              },
                              child: Center(
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.contain,
                                      )
                                    : const CircularProgressIndicator(
                                        color: Color(0xFF10B981),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Squircle Cutout Overlay
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(viewportSize, viewportSize),
                          painter: CropMaskPainter(cutoutSize: logicalCutoutSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Bottom Controls Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B), // Slate 800
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Slider Row
                    Row(
                      children: [
                        const Icon(Icons.zoom_out_rounded, color: Colors.grey, size: 20),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF10B981),
                              inactiveTrackColor: const Color(0xFF475569),
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFF10B981).withOpacity(0.12),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _currentZoom.clamp(0.5, 5.0),
                              min: 0.5,
                              max: 5.0,
                              onChanged: _updateZoom,
                            ),
                          ),
                        ),
                        const Icon(Icons.zoom_in_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Rotate Button
                        TextButton.icon(
                          onPressed: _rotateImage,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.rotate_right_rounded, color: Color(0xFF10B981)),
                          label: Text(AppStrings.get('rotate', lang)),
                        ),
                        
                        // Reset Button
                        TextButton.icon(
                          onPressed: _resetAll,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                          label: Text(AppStrings.get('reset', lang)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom squircle mask painter
class CropMaskPainter extends CustomPainter {
  final double cutoutSize;

  CropMaskPainter({required this.cutoutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7) // Semi-transparent mask
      ..style = PaintingStyle.fill;

    // Cutout rect in the center
    final double left = (size.width - cutoutSize) / 2;
    final double top = (size.height - cutoutSize) / 2;
    final cutoutRect = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    // Using path subtraction to draw mask with hole
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(cutoutSize * 0.32)));

    final finalPath = Path.combine(PathOperation.difference, maskPath, cutoutPath);
    canvas.drawPath(finalPath, paint);

    // Draw thin rounded border preview
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, Radius.circular(cutoutSize * 0.32)), 
      borderPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
