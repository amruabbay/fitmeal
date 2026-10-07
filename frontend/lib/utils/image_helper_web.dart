import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

String createBlobUrl(Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/png');
  return html.Url.createObjectUrlFromBlob(blob);
}

Future<Uint8List> cropImageWeb({
  required String imagePath,
  required double scale,
  required double tx,
  required double ty,
  required int rotationQuarter,
  required double viewportSize,
  required double cutoutSize,
}) async {
  final img = html.ImageElement();
  img.src = imagePath;
  
  try {
    await img.decode();
  } catch (e) {
    throw Exception('Failed to load and decode image for cropping: $e');
  }
  
  final double naturalWidth = img.naturalWidth.toDouble();
  final double naturalHeight = img.naturalHeight.toDouble();
  final double r = naturalWidth / naturalHeight;
  
  double fittedWidth;
  double fittedHeight;
  double x0;
  double y0;
  
  // Recreate Flutter's BoxFit.contain behavior
  if (r > 1) {
    fittedWidth = viewportSize;
    fittedHeight = viewportSize / r;
    x0 = 0;
    y0 = (viewportSize - fittedHeight) / 2;
  } else {
    fittedHeight = viewportSize;
    fittedWidth = viewportSize * r;
    x0 = (viewportSize - fittedWidth) / 2;
    y0 = 0;
  }
  
  // High-resolution output crop size
  const double outputSize = 480.0;
  final double ratio = outputSize / cutoutSize; // 480 / 240 = 2.0
  final double cutoutOffset = (viewportSize - cutoutSize) / 2; // 50.0
  
  final canvas = html.CanvasElement(
    width: outputSize.toInt(),
    height: outputSize.toInt(),
  );
  final ctx = canvas.context2D;
  
  // 1. Clear canvas
  ctx.clearRect(0, 0, outputSize, outputSize);
  
  // 2. Rotate around center of canvas
  ctx.translate(outputSize / 2, outputSize / 2);
  ctx.rotate(rotationQuarter * 90 * 3.141592653589793 / 180);
  ctx.translate(-outputSize / 2, -outputSize / 2);
  
  // 3. Scale to output high-resolution size
  ctx.scale(ratio, ratio);
  
  // 4. Apply InteractiveViewer translation & zoom scale relative to cutout bounds
  ctx.translate(tx - cutoutOffset, ty - cutoutOffset);
  ctx.scale(scale, scale);
  
  // 5. Draw the fitted image
  ctx.drawImageScaled(img, x0, y0, fittedWidth, fittedHeight);
  
  // Extract bytes
  final dataUrl = canvas.toDataUrl('image/png');
  final base64String = dataUrl.split(',').last;
  return base64Decode(base64String);
}

Future<XFile?> pickImagePlatform(bool isCamera) async {
  final completer = Completer<XFile?>();
  final html.FileUploadInputElement input = html.FileUploadInputElement();
  input.accept = 'image/*';
  if (isCamera) {
    input.setAttribute('capture', 'environment');
  }

  html.document.body!.append(input);
  input.style.display = 'none';

  input.onChange.listen((e) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final url = html.Url.createObjectUrl(file);
      completer.complete(XFile(url, name: file.name, length: file.size));
    } else {
      completer.complete(null);
    }
    input.remove();
  });

  input.click();

  return completer.future;
}
