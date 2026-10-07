import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

String createBlobUrl(Uint8List bytes) {
  throw UnsupportedError('Cannot create blob URL on this platform');
}

Future<Uint8List> cropImageWeb({
  required String imagePath,
  required double scale,
  required double tx,
  required double ty,
  required int rotationQuarter,
  required double viewportSize,
  required double cutoutSize,
}) {
  throw UnsupportedError('Cannot crop image on this platform');
}

Future<XFile?> pickImagePlatform(bool isCamera) async {
  final picker = ImagePicker();
  return await picker.pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 90,
  );
}
