import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ColorExtractor {
  static LinearGradient createGradient(Color baseColor, Brightness brightness) {
    // Adjust opacity based on theme brightness
    final double opacity = brightness == Brightness.dark ? 0.6 : 0.8;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(opacity),
        baseColor.withOpacity(opacity * 0.7),
        baseColor.withOpacity(opacity * 0.5),
      ],
    );
  }

  /// Darken a color by a given factor
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Lighten a color by a given factor
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Extracts the dominant color from a given ImageProvider
  static Future<Color> getDominantColorFromImage(
    ImageProvider imageProvider,
  ) async {
    final completer = Completer<ImageInfo>();
    final stream = imageProvider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    final imageInfo = await completer.future;
    stream.removeListener(listener);

    final image = imageInfo.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return Colors.grey;

    final pixels = byteData.buffer.asUint8List();
    int r = 0, g = 0, b = 0, count = 0;

    for (int i = 0; i < pixels.length; i += 4) {
      r += (pixels[i]);
      g += pixels[i + 1];
      b += (pixels[i + 2]);
      count++;
    }

    r = (r / count).round();
    g = (g / count).round();
    b = (b / count).round();

    return Color.fromARGB(255, r, g, b);
  }
}
