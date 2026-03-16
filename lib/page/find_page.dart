import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_constants.dart';
import '../utils/ocr_service.dart';
import '../utils/llm_service.dart';
import '../models/schedule.dart';
import 'ocr_confirm_page.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key});

  @override
  State<FindPage> createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final OCRService _ocrService = OCRService();
  final LLMService _llmService = LLMService();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {
        'title': 'AI 识图建历',
        'subtitle': '拍照一键自动提取日程',
        'color': 0xFFBBDEFB,
        'icon': Icons.auto_awesome,
        'image': 'assets/images/image_commit.png',
      },
      {
        'title': '敬请期待',
        'subtitle': '更多智能功能开发中',
        'color': 0xFFC8E6C9,
        'icon': Icons.more_horiz,
        'image': 'assets/images/more.png',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _buildFeatureCard(context, feature);
        },
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature) {
    final String? imagePath = feature['image'] as String?;
    final Color themeColor = Color(feature['color'] as int);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (feature['title'] == 'AI 识图建历') {
            _showImagePickerOptions(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${feature['title']} 功能即将上线')),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: themeColor.withOpacity(0.1),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          feature['icon'] as IconData,
                          size: 48,
                          color: themeColor,
                        ),
                      )
                    : Icon(
                        feature['icon'] as IconData,
                        size: 48,
                        color: themeColor,
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text(
                    '拍摄照片',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bContext);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text(
                    '从相册选择',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bContext);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('图片已获取，正在提取日程信息...')),
        );

        // 执行 OCR 识别
        final String ocrResult = await _ocrService.processImage(image.path);

        // 使用 LLMService 进行智能解析
        final dynamic llmResult = await _llmService.sendToBot(ocrResult);

        if (mounted) {
          List<Schedule> parsedSchedules = [];
          
          if (llmResult is List) {
            parsedSchedules = llmResult.map((data) => _mapToSchedule(data)).toList();
          } else if (llmResult is Map<String, dynamic>) {
            parsedSchedules = [_mapToSchedule(llmResult)];
          } else {
            _showResultDialog(context, llmResult.toString());
            return;
          }

          // 跳转到核对页面，不再传递耗时参数
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OcrConfirmPage(
                initialSchedules: parsedSchedules,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('处理出错: $e')),
        );
      }
    }
  }

  Schedule _mapToSchedule(Map<String, dynamic> data) {
    final String title = data['title'] ?? '未命名日程';
    final String? description = data['description'];
    final String? location = data['location'];
    DateTime dateTime = DateTime.now();
    try {
      if (data['time'] != null) {
        dateTime = DateTime.parse(data['time']);
      }
    } catch (_) {}

    return Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString() + (data.hashCode.toString()),
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
    );
  }

  void _showResultDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('提示', style: TextStyle(color: AppColors.textMain)),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
