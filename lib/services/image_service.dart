import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageService {
  Future<String?> generatePlaylistCollage(
    List<String?> artworkPaths,
    String playlistName,
  ) async {
    try {
      if (artworkPaths.isEmpty) return null;

      // Filter valid paths
      final validPaths = artworkPaths
          .where((path) => path != null && path.isNotEmpty)
          .take(4)
          .toList();

      if (validPaths.isEmpty) return null;

      // Ensure we have 4 images (repeat if necessary)
      final List<String?> pathsToUse = [...validPaths];
      if (pathsToUse.length < 4) {
        // If we have less than 4, fill with the existing ones
        while (pathsToUse.length < 4) {
          pathsToUse.add(pathsToUse[pathsToUse.length % validPaths.length]);
        }
      }

      final images = await Future.wait(
        pathsToUse.map((path) => _loadImage(path!)).toList(),
      );

      // Create a recorder
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final size = 300.0; // Export size
      final halfSize = size / 2;

      final paint = ui.Paint()..isAntiAlias = true;

      // Draw images in 2x2 grid
      // 0 | 1
      // -----
      // 2 | 3

      await _drawImage(canvas, images[0], 0, 0, halfSize, paint);
      await _drawImage(canvas, images[1], halfSize, 0, halfSize, paint);
      await _drawImage(canvas, images[2], 0, halfSize, halfSize, paint);
      await _drawImage(canvas, images[3], halfSize, halfSize, halfSize, paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = await _saveImage(bytes, playlistName);
      return file.path;
    } catch (e) {
      debugPrint('Error generating collage: $e');
      return null;
    }
  }

  Future<ui.Image?> _loadImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('http')) {
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
      } else {
        final file = File(path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          return null;
        }
      }
      return await _decodeImage(bytes);
    } catch (e) {
      debugPrint('Error loading image $path: $e');
      return null;
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _drawImage(
    ui.Canvas canvas,
    ui.Image? image,
    double x,
    double y,
    double size,
    ui.Paint paint,
  ) async {
    if (image == null) {
      // Draw placeholder
      canvas.drawRect(
        Rect.fromLTWH(x, y, size, size),
        paint..color = const Color(0xFF333333),
      );
      return;
    }

    // Center crop
    final srcSize = image.width < image.height
        ? image.width.toDouble()
        : image.height.toDouble();
    final srcX = (image.width - srcSize) / 2;
    final srcY = (image.height - srcSize) / 2;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcX, srcY, srcSize, srcSize),
      Rect.fromLTWH(x, y, size, size),
      paint,
    );
  }

  Future<File> _saveImage(Uint8List bytes, String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'collage_${DateTime.now().millisecondsSinceEpoch}_$name.png';
    // Sanitize filename
    final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s\.]'), '');
    final file = File('${directory.path}/$safeFileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
