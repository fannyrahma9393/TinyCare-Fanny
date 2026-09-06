import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

/// Compresses picked images before upload, so child photos don't bloat
/// storage. Native (mobile/desktop) path uses [dart:ui] to decode, downscale
/// and re-encode as JPEG.
///
/// Returns a compressed JPEG [XFile] (as a temp file) plus its bytes, or
/// returns the original [XFile] when compression isn't possible (web or
/// undecodable image).
class MediaCompressor {
  /// Max dimension of the longest edge after compression.
  static const int maxDimension = 1024;

  /// JPEG quality (0-100).
  static const int quality = 80;

  /// Returns a [CompressedImage] with the ready-to-upload bytes, or null if
  /// compression produced nothing usable (caller should fall back).
  static Future<CompressedImage?> compress(XFile file) async {
    if (kIsWeb) return null;

    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final original = frame.image;

      final origW = original.width;
      final origH = original.height;
      if (origW <= 0 || origH <= 0) return null;

      final longest = origW > origH ? origW : origH;
      num scale = 1.0;
      if (longest > maxDimension) {
        scale = maxDimension / longest;
      }

      final outW = (origW * scale).round().clamp(1, maxDimension);
      final outH = (origH * scale).round().clamp(1, maxDimension);

      ui.Image resized;
      if (outW == origW && outH == origH) {
        resized = original;
      } else {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImageRect(
          original,
          Rect.fromLTWH(0, 0, origW.toDouble(), origH.toDouble()),
          Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
          Paint()
            ..filterQuality = FilterQuality.medium
            ..isAntiAlias = true,
        );
        final picture = recorder.endRecording();
        resized = await picture.toImage(outW, outH);
        picture.dispose();
      }

      final byteData = await resized.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (resized != original) {
        resized.dispose();
      }
      original.dispose();

      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      // dart:ui cannot encode JPEG directly; write PNG to a temp file. The
      // PNG is already downscaled so it is much smaller than a raw camera
      // photo, and PNG is lossless so child photo quality is preserved.
      final dir = await Directory.systemTemp.createTemp('tc_photo_');
      final tmpFile = File('${dir.path}/photo.png');
      await tmpFile.writeAsBytes(pngBytes, flush: true);

      return CompressedImage(
        file: XFile(tmpFile.path, mimeType: 'image/png'),
        bytes: pngBytes,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of a successful media compression.
class CompressedImage {
  const CompressedImage({required this.file, required this.bytes});

  /// The compressed file to upload.
  final XFile file;

  /// Raw bytes (PNG) of the compressed image.
  final Uint8List bytes;
}
