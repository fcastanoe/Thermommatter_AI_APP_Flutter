import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../shared/models/patient.dart';

/// Represents the extracted thermal range
class ThermalRange {
  final double minTemp;
  final double maxTemp;
  final bool wasManuallyCorrected;

  ThermalRange({
    required this.minTemp,
    required this.maxTemp,
    this.wasManuallyCorrected = false,
  });

  bool get isValid => minTemp >= 15 && minTemp <= 40 && maxTemp >= 15 && maxTemp <= 40 && minTemp < maxTemp;
}

class OcrService {
  static final _numberRegex = RegExp(r'\d+(?:\.\d+)?');

  /// Extracts the max (top) and min (bottom) temperatures from an image
  /// using Google ML Kit and bounding box estimations.
  static Future<ThermalRange?> extractVisibleTemperatureRange(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Collect all numbers found
      final allNumbers = <double>[];
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final matches = _numberRegex.allMatches(line.text);
          for (final m in matches) {
            final valStr = m.group(0);
            if (valStr != null) {
              final val = double.tryParse(valStr);
              if (val != null) allNumbers.add(val);
            }
          }
        }
      }

      if (allNumbers.isNotEmpty) {
        // Filtramos valores irrealistas (ej. el "1" o "2" que se confunde con ruido)
        final realisticTemps = allNumbers.where((t) => t >= 15.0 && t <= 45.0).toList();
        if (realisticTemps.length >= 2) {
          realisticTemps.sort();
          return ThermalRange(
            minTemp: realisticTemps.first,
            maxTemp: realisticTemps.last,
          );
        }
      }
      return null;
    } catch (e) {
      print('OCR Error: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }
}
