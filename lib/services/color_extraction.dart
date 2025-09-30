import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:material_color_utilities/material_color_utilities.dart' as mcu;
import 'dart:math';

class ColorExtractionService {
  /// Extracts dominant colors from an image provider.
  /// Returns a list of colors suitable for UI theming.
  static Future<List<Color>> getColorsFromImage(ImageProvider provider) async {
    try {
      if (provider is FileImage) {
        final bytes = await provider.file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) return [];

        final int totalPixels = image.width * image.height;
        final Random random = Random();

        // 如果像素总数小于2000，直接计算所有像素的平均颜色
        if (totalPixels < 2000) {
          return _calculateAverageColorsDirect(image);
        } else {
          // 否则随机抽取2000个像素计算平均颜色
          return _calculateAverageColorsSampled(image, random);
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error getting colors from image: $e');
      return [];
    }
  }

  /// 直接计算所有像素的平均颜色（适用于小图片）
  static List<Color> _calculateAverageColorsDirect(img.Image image) {
    int totalR = 0, totalG = 0, totalB = 0, totalA = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        if (a > 0) {
          totalR += r;
          totalG += g;
          totalB += b;
          totalA += a;
          pixelCount++;
        }
      }
    }

    if (pixelCount == 0) return [];

    // 计算平均颜色
    final avgR = totalR ~/ pixelCount;
    final avgG = totalG ~/ pixelCount;
    final avgB = totalB ~/ pixelCount;
    final avgA = totalA ~/ pixelCount;

    final avgArgb = (avgA << 24) | (avgR << 16) | (avgG << 8) | avgB;

    // 使用 material_color_utilities 生成主题色
    final colorToCount = {avgArgb: pixelCount};
    final List<int> filteredResults = mcu.Score.score(
      colorToCount,
      desired: 1,
      filter: true,
    );
    final List<int> scoredResults = mcu.Score.score(
      colorToCount,
      desired: 4,
      filter: false,
    );

    return <dynamic>{
      ...filteredResults,
      ...scoredResults,
    }.toList().map((argb) => Color(argb)).toList();
  }

  /// 随机抽样计算平均颜色（适用于大图片）
  static List<Color> _calculateAverageColorsSampled(img.Image image, Random random) {
    const int sampleSize = 2000;
    int totalR = 0, totalG = 0, totalB = 0, totalA = 0;

    for (int i = 0; i < sampleSize; i++) {
      // 随机选择像素位置
      final x = random.nextInt(image.width);
      final y = random.nextInt(image.height);

      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = pixel.a.toInt();

      if (a > 0) {
        totalR += r;
        totalG += g;
        totalB += b;
        totalA += a;
      }
    }

    // 计算平均颜色
    final avgR = totalR ~/ sampleSize;
    final avgG = totalG ~/ sampleSize;
    final avgB = totalB ~/ sampleSize;
    final avgA = totalA ~/ sampleSize;

    final avgArgb = (avgA << 24) | (avgR << 16) | (avgG << 8) | avgB;

    // 使用 material_color_utilities 生成主题色
    final colorToCount = {avgArgb: sampleSize};
    final List<int> filteredResults = mcu.Score.score(
      colorToCount,
      desired: 1,
      filter: true,
    );
    final List<int> scoredResults = mcu.Score.score(
      colorToCount,
      desired: 4,
      filter: false,
    );

    return <dynamic>{
      ...filteredResults,
      ...scoredResults,
    }.toList().map((argb) => Color(argb)).toList();
  }
}
