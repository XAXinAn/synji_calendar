import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../utils/ocr_service.dart';
import '../utils/llm_service.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import 'ocr_confirm_page.dart';
import 'login_page.dart';
import 'group_sharing_page.dart';

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
        'subtitle': '拍照自动提取日程内容',
        'color': AppColors.primary,
        'icon': Icons.camera_enhance_rounded,
        'tag': '智能',
      },
      {
        'title': '组内日程共享',
        'subtitle': '团队协作，日程同步共享',
        'color': Colors.blue,
        'icon': Icons.group_rounded,
        'tag': '共享',
      },
      {
        'title': '语音快速添加',
        'subtitle': '说话即刻转化为日程',
        'color': AppColors.success,
        'icon': Icons.mic_rounded,
        'tag': '待上线',
      },
      {
        'title': '链接一键识别',
        'subtitle': '自动识别链接中的会议',
        'color': AppColors.warning,
        'icon': Icons.link_rounded,
        'tag': '规划中',
      },
      {
        'title': '课程表导入',
        'subtitle': '适配主流大学课表导入',
        'color': Colors.purple,
        'icon': Icons.school_rounded,
        'tag': '规划中',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '智能探索',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '利用 AI 技术，让日程管理更简单',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _buildFeatureCard(context, feature);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature) {
    final Color themeColor = feature['color'] as Color;
    final String tag = feature['tag'];
    final bool isAvailable = tag == '智能' || tag == '共享';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
          onTap: () {
            final authService = context.read<AuthService>();
            if (!authService.isAuthenticated) {
              _showLoginPrompt(context);
              return;
            }

            if (feature['title'] == 'AI 识图建历') {
              _showImagePickerOptions(context);
            } else if (feature['title'] == '组内日程共享') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupSharingPage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${feature['title']} 正在全力开发中...'),
                  behavior: SnackBarBehavior.fixed,
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF323232),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        size: 24,
                        color: themeColor,
                      ),
                    ),
                    if (tag != '智能')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tag == '共享' 
                            ? AppColors.primary.withOpacity(0.1) 
                            : AppColors.textLightGrey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10, 
                            color: tag == '共享' ? AppColors.primary : AppColors.textGrey,
                            fontWeight: tag == '共享' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
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
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要登录'),
        content: const Text('智能探索功能需要登录后才能使用，是否立即前往登录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('再看看', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('去登录'),
          ),
        ],
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
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  title: const Text('拍摄照片', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(bContext);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  title: const Text('从相册选择', style: TextStyle(fontWeight: FontWeight.w500)),
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
    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();
    
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        scheduleService.setProcessing(true, message: '正在从图片识别内容...', progress: 0.3);
        final String ocrResult = await _ocrService.processImage(image.path);
        scheduleService.setProcessing(true, message: 'AI 正在分析日程信息...', progress: 0.7);

        final dynamic llmResult = await _llmService.sendToBot(
          ocrResult, 
          token: authService.user?.token
        );

        if (mounted) {
          scheduleService.setProcessing(false);
          List<Schedule> parsedSchedules = [];
          if (llmResult is List) {
            parsedSchedules = llmResult.map((data) => _mapToSchedule(data, 0)).toList();
          } else if (llmResult is Map<String, dynamic>) {
            parsedSchedules = [_mapToSchedule(llmResult, 0)];
          } else {
            _showResultDialog(context, llmResult.toString());
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => OcrConfirmPage(initialSchedules: parsedSchedules)));
        }
      }
    } catch (e) {
      if (mounted) {
        scheduleService.setProcessing(false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('处理出错: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.fixed));
      }
    }
  }

  Schedule _mapToSchedule(Map<String, dynamic> data, int index) {
    DateTime dateTime = DateTime.now();
    try { if (data['time'] != null) dateTime = DateTime.parse(data['time']); } catch (_) {}
    return Schedule(
      id: '${DateTime.now().millisecondsSinceEpoch}_$index',
      title: data['title'] ?? '未命名日程',
      description: data['description'],
      dateTime: dateTime,
      location: data['location'],
    );
  }

  void _showResultDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }
}
