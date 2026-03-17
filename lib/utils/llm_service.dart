import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// 日程解析 LLM 服务 (后端代理版)
/// 出于安全性考虑，所有 LLM 调用均通过后端转发，不在前端暴露 API Key
class LLMService {
  late final Dio _dio;

  LLMService() {
    _dio = Dio(BaseOptions(
      // 统一指向后端 Base URL
      baseUrl: 'http://localhost:8080/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ));
  }

  /// 将 OCR 识别到的文字发送给后端进行 AI 解析
  /// [token] 用户鉴权令牌
  /// [ocrText] OCR 识别出的原始文本
  Future<dynamic> sendToBot(String ocrText, {String? token}) async {
    if (token == null) return '错误：未登录，无法使用 AI 功能';

    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post(
        '/ai/parse-schedule',
        data: {
          'text': ocrText,
          'context': {
            'currentTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            'currentYear': DateTime.now().year.toString(),
          }
        },
      );

      final data = response.data;
      if (data['code'] == 200) {
        // 直接返回后端解析好的 JSON 数据 (Schedule 列表或对象)
        return data['data'];
      } else {
        return data['message'] ?? 'AI 解析失败';
      }
    } on DioException catch (e) {
      return '网络错误: ${e.message}';
    } catch (e) {
      return '解析异常: $e';
    }
  }
}
