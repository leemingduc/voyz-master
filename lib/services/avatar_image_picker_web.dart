// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
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

Future<PickedAvatarImage?> pickAvatarImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp'
    ..multiple = false;

  final completer = Completer<PickedAvatarImage?>();
  input.onChange.first.then((_) async {
    final file = input.files?.isEmpty ?? true ? null : input.files!.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final result = reader.result;
    final bytes = switch (result) {
      ByteBuffer buffer => buffer.asUint8List(),
      Uint8List typedBytes => typedBytes,
      List<int> list => Uint8List.fromList(list),
      _ => throw StateError('Could not read selected image.'),
    };

    completer.complete(
      PickedAvatarImage(
        bytes: bytes,
        fileName: file.name,
        mimeType: file.type.isEmpty ? 'image/png' : file.type,
      ),
    );
  });

  input.click();
  return completer.future;
}

Future<Uint8List> cropAvatarImage({
  required Uint8List bytes,
  required String mimeType,
  required double zoom,
  required double offsetX,
  required double offsetY,
  int size = 512,
}) async {
  final image = await _loadImage(bytes, mimeType);
  final canvas = html.CanvasElement(width: size, height: size);
  final context = canvas.context2D;

  context
    ..fillStyle = '#12182B'
    ..fillRect(0, 0, size, size);

  final coverScale = math.max(size / image.width!, size / image.height!);
  final scale = coverScale * zoom.clamp(1.0, 3.0);
  final drawWidth = image.width! * scale;
  final drawHeight = image.height! * scale;
  final x = (size - drawWidth) / 2 + (offsetX.clamp(-1.0, 1.0) * size * 0.28);
  final y = (size - drawHeight) / 2 + (offsetY.clamp(-1.0, 1.0) * size * 0.28);

  context.drawImageScaled(image, x, y, drawWidth, drawHeight);

  final dataUrl = canvas.toDataUrl('image/png');
  final commaIndex = dataUrl.indexOf(',');
  final encoded = commaIndex == -1 ? dataUrl : dataUrl.substring(commaIndex + 1);
  return base64Decode(encoded);
}

Future<html.ImageElement> _loadImage(Uint8List bytes, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final image = html.ImageElement(src: url);

  try {
    await image.onLoad.first;
    return image;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
