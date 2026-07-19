import 'dart:typed_data';

class PickedAvatarImage {
  const PickedAvatarImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

Future<PickedAvatarImage?> pickAvatarImage() {
  throw UnsupportedError('Avatar upload is currently available on web only.');
}

Future<Uint8List> cropAvatarImage({
  required Uint8List bytes,
  required String mimeType,
  required double zoom,
  required double offsetX,
  required double offsetY,
  int size = 512,
}) {
  throw UnsupportedError('Avatar editing is currently available on web only.');
}
