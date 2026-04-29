import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class SegmentationService {
  static Interpreter? _interpreter;

  /// Carga el modelo TensorFlow Lite
  static Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      // Usamos 1 hilo para evitar bloqueos en emuladores limitados
      final options = InterpreterOptions()..threads = 1;
      
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_fp16.tflite',
        options: options,
      );
      
      print('✅ Modelo TFLite cargado correctamente');
      print('📥 Inputs: ${_interpreter!.getInputTensors().map((t) => '${t.name}: ${t.shape} (${t.type})').toList()}');
      print('📤 Outputs: ${_interpreter!.getOutputTensors().map((t) => '${t.name}: ${t.shape} (${t.type})').toList()}');
    } catch (e) {
      print('❌ Error cargando el modelo TFLite: $e');
    }
  }

  /// Procesa la imagen y genera `mask.png` usando TFLite
  static Future<String?> processAndSaveMask(String imagePath, String outputDirPath) async {
    await loadModel();
    if (_interpreter == null) throw Exception('Interpreter is null. Failed to load model.');

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    // Verificamos dimensiones esperadas (asumimos la primera entrada/salida)
    // Nuevo modelo: input=[1,256,256,3]  output=[1,1,256,256]
    final inputShape = inputTensors[0].shape;
    final outputShape = outputTensors[0].shape;

    // 1) Leer imagen original
    final bytes = await File(imagePath).readAsBytes();
    img.Image? original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode image.');

    print('🖼 Redimensionando imagen a ${inputShape[1]}x${inputShape[2]}');
    // 2) Redimensionar al tamaño que el modelo espera
    img.Image resized = img.copyResize(
      original, 
      width: inputShape[1], 
      height: inputShape[2], 
      interpolation: img.Interpolation.linear
    );

    print('⚙️ Creando tensor de entrada... Shape: $inputShape');
    // 3) Construir tensor de entrada normalizado (0-1)
    final input = Float32List(inputShape.reduce((a, b) => a * b));
    int inputIdx = 0;

    for (int y = 0; y < inputShape[1]; y++) {
      for (int x = 0; x < inputShape[2]; x++) {
        final pixel = resized.getPixel(x, y);
        double v = ((pixel.r + pixel.g + pixel.b) / (3.0 * 255.0));
        input[inputIdx++] = v;
        input[inputIdx++] = v;
        input[inputIdx++] = v;
      }
    }

    print('🚀 Ejecutando inferencia...');
    // 4) Tensor de salida
    final output = Float32List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);

    // 5) Ejecutar inferencia
    final stopwatch = Stopwatch()..start();
    final shapedInput = input.reshape(inputShape);
    
    _interpreter!.run(shapedInput, output);
    print('✅ Inferencia completada en ${stopwatch.elapsedMilliseconds} ms');

    // 6) Postproceso: convertir float array a bitmap en escala de gris.
    //    Nuevo modelo: output shape = [1, 1, H, W]  (sigmoid por píxel)
    //    Acceso: outList[0][0][y][x]
    final int maskH = outputShape[2]; // 256
    final int maskW = outputShape[3]; // 256
    img.Image mask = img.Image(width: maskW, height: maskH);
    final outList = output as List;

    for (int y = 0; y < maskH; y++) {
      for (int x = 0; x < maskW; x++) {
        // Valor sigmoid: 1 = pie, 0 = fondo
        final double prob = outList[0][0][y][x] as double;
        if (prob > 0.5) {
          mask.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // Blanco
        } else {
          mask.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // Negro
        }
      }
    }

    // 7) Guardar la máscara
    final Directory outDir = Directory(outputDirPath);
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    
    final outputPath = '${outDir.path}/mask.png';
    final maskBytes = img.encodePng(mask);
    await File(outputPath).writeAsBytes(maskBytes);
    
    print('💾 Máscara guardada en: $outputPath');
    return outputPath;
  }
}
