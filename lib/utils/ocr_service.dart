import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // 1. 初始化识别器（指定语言，如中文）
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    // 2. 识别文字
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    // 3. 提取结果
    String text = recognizedText.text;
    
    // 如果需要更精细的控制，可以遍历 block -> line -> element
    print('--- OCR 识别开始 ---');
    for (TextBlock block in recognizedText.blocks) {
      print('Detected block: ${block.text}');
    }
    print('--- OCR 识别结束 ---');

    return text;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
