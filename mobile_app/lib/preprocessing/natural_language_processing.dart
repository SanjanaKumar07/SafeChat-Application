import 'package:chat_app/preprocessing/embeddingBuilder.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class NLP {
  static late Interpreter interpreter;

  static loadModel() async {
    interpreter = await Interpreter.fromAsset('tflite/FirstLSTM.tflite');
  }

  

  static double predict(
      String message, Map<String, List<dynamic>> embeddingData) {
    var input = [EmbeddingBuilder.preprocess(message, embeddingData)];

    var output = [
      [0.0]
    ];

    interpreter.run(input, output);
    
    return output[0][0];
  }
}
