import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierHelper {
  late final Interpreter _interpreter;
  late final List<String> _labels;
  final int inputSize = 224;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/id_document_classifier.tflite');
    final rawLabels = await rootBundle.loadString('assets/models/labels.txt');
    _labels = rawLabels.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final inputType = _interpreter.getInputTensor(0).type;
    debugPrint("🎯 Input type: $inputType");
  }

  Future<String> classify(File imageFile) async {
    final Image? image = decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("Image illisible");

    final Image resized = copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            final r = (pixel.r.toDouble() - 127.5) / 127.5;
            final g = (pixel.g.toDouble() - 127.5) / 127.5;
            final b = (pixel.b.toDouble() - 127.5) / 127.5;
            return [r, g, b];
          },
        ),
      ),
    );

    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter.run(input, output);

    final result = output[0] as List<double>;
    debugPrint('🧪 Scores bruts : $result');

    final maxIndex = result.indexWhere((e) => e == result.reduce((a, b) => a > b ? a : b));
    final confidence = result[maxIndex];

    debugPrint('Prediction max index: $maxIndex');
    debugPrint('Confidence values: ${result.map((v) => (v * 100).toStringAsFixed(2)).toList()}');
    debugPrint('Labels: $_labels');

    return "${_labels[maxIndex]} (${(confidence * 100).toStringAsFixed(1)}%)";
  }

  Future<Map<String, dynamic>> classifyWithScores(File imageFile) async {
    final Image? image = decodeImage(await imageFile.readAsBytes());
    if (image == null) throw Exception("Image illisible");

    final Image resized = copyResize(image, width: inputSize, height: inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            final r = (pixel.r.toDouble() - 127.5) / 127.5;
            final g = (pixel.g.toDouble() - 127.5) / 127.5;
            final b = (pixel.b.toDouble() - 127.5) / 127.5;
            return [r, g, b];
          },
        ),
      ),
    );

    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter.run(input, output);

    final result = output[0] as List<double>;
    debugPrint('🧪 Scores bruts : $result');

    final maxIndex = result.indexWhere((e) => e == result.reduce((a, b) => a > b ? a : b));
    final label = _labels[maxIndex];

    final scoresMap = <String, String>{};
    for (int i = 0; i < _labels.length; i++) {
      scoresMap[_labels[i]] = (result[i] * 100).toStringAsFixed(1) + '%';
    }

    debugPrint('Prediction max index: $maxIndex');
    debugPrint('Confidence values: ${result.map((v) => (v * 100).toStringAsFixed(2)).toList()}');
    debugPrint('Labels: $_labels');

    return {
      'label': "$label (${(result[maxIndex] * 100).toStringAsFixed(1)}%)",
      'scores': scoresMap,
      'labels': _labels,
    };
  }
}
