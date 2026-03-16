import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// 阿里百炼 LLM 服务
class LLMService {
  // 生产环境安全方案：通过 --dart-define 注入 API Key
  // 运行命令示例: flutter run --dart-define=DASHSCOPE_API_KEY=your_real_key
  static const String _apiKey = String.fromEnvironment('DASHSCOPE_API_KEY', defaultValue: '');
  
  static const String _model = 'qwen-plus'; 
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20), 
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  Future<dynamic> sendToBot(String query) async {
    // 检查 Key 是否已注入
    if (_apiKey.isEmpty) {
      return '错误：未配置 DASHSCOPE_API_KEY。请通过 --dart-define 注入。';
    }

    return _executeRequest(query, _apiKey);
  }

  Future<dynamic> _executeRequest(String query, String apiKey) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
      
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': '你是一个高效的JSON日程解析器，严禁输出任何废话。'},
            {'role': 'user', 'content': _buildProfessionalPrompt(query)}
          ],
          'stream': false,
          'temperature': 0.1, 
          'top_p': 1,
        },
      );

      final data = response.data;
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final String content = data['choices'][0]['message']['content'];
        return _parseResponse(content);
      }
      return 'LLM 响应异常';
    } on DioException catch (e) {
      return '网络错误: ${e.message}';
    } catch (e) {
      return '系统错误: $e';
    }
  }

  String _buildProfessionalPrompt(String text) {
    final now = DateTime.now();
    final currentTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final currentYear = now.year.toString();

    return '''# 任务
将 OCR 文本转为 JSON 日程。当前时间：$currentTimeStr。

# 规则
1. 年份缺失补 $currentYear，相对时间基于 $currentTimeStr 计算。
2. 必须包含字段：title, time (格式: YYYY-MM-DD HH:mm:ss), location, description。
3. description 缺失填"无补充信息"。
4. 严禁输出 Markdown 标签，仅返回纯 JSON。

# 待处理文本
$text''';
  }

  dynamic _parseResponse(String content) {
    try {
      final RegExp jsonRegex = RegExp(r'(\{[\s\S]*\}|\[[\s\S]*\])', dotAll: true);
      final match = jsonRegex.stringMatch(content);
      
      if (match != null) {
        return jsonDecode(match);
      }
      return content.trim();
    } catch (e) {
      return content.trim();
    }
  }
}
