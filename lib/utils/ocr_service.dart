import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;

class OCRService {
  static const Set<String> _supportedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.heif',
    '.bmp',
    '.gif',
    '.webp',
    '.tif',
    '.tiff',
  };

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  Future<String> processImage(String imagePath) async {
    final String normalizedPath = normalizePath(imagePath);
    final File imageFile = File(normalizedPath);
    final bool exists = await imageFile.exists();
    if (!exists) {
      throw Exception('图片文件不存在，请重新选择图片');
    }

    final String extension = p.extension(normalizedPath).toLowerCase();
    if (extension.isNotEmpty && !_supportedExtensions.contains(extension)) {
      throw Exception('不支持的图片格式: $extension');
    }

    final inputImage = InputImage.fromFilePath(normalizedPath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    String text = recognizedText.text;

    print('--- OCR 识别开始 ---');
    for (TextBlock block in recognizedText.blocks) {
      print('Detected block: ${block.text}');
    }
    print('--- OCR 识别结束 ---');

    return text;
  }

  static String normalizePath(String rawPath) {
    final String path = rawPath.trim();
    final Uri? uri = Uri.tryParse(path);

    if (uri != null && uri.hasScheme) {
      if (uri.scheme == 'file') {
        return uri.toFilePath();
      }
      if (uri.scheme == 'ph' || uri.scheme == 'assets-library') {
        return path;
      }
    }

    return Uri.decodeFull(path);
  }

  static bool isPhotosAssetUri(String path) {
    return path.startsWith('ph://') || path.startsWith('assets-library://');
  }

  static bool isLikelyImagePath(String rawPath) {
    final String path = normalizePath(rawPath);
    final String extension = p.extension(path).toLowerCase();
    return extension.isEmpty || _supportedExtensions.contains(extension);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
