import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:synji_calendar/utils/app_constants.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../utils/ocr_service.dart';
import '../utils/llm_service.dart';
import '../models/schedule.dart';
import 'home_page.dart';
import 'find_page.dart';
import 'profile_page.dart';
import 'add_schedule_page.dart';
import 'search_page.dart';
import 'ocr_confirm_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _intentDataStreamSubscription;
  final OCRService _ocrService = OCRService();
  final LLMService _llmService = LLMService();

  final List<Widget> _pages = const [
    HomePage(),
    FindPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSharingIntent();
    });
  }

  void _initSharingIntent() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedImage(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedImage(value.first.path);
      }
      ReceiveSharingIntent.instance.reset();
    }).catchError((err) {
      debugPrint("getInitialMedia error: $err");
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _handleSharedImage(String path) async {
    String cleanPath = path;
    if (path.startsWith('file://')) {
      cleanPath = path.replaceFirst('file://', '');
    }

    if (!mounted) return;

    setState(() {
      _selectedIndex = 0;
    });

    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();

    try {
      final file = File(cleanPath);
      if (!await file.exists()) return;

      scheduleService.setProcessing(true, message: '正在从图片识别内容...', progress: 0.3);

      final String ocrResult = await _ocrService.processImage(cleanPath);
      if (ocrResult.trim().isEmpty) throw "未能识别到图片中的文字";

      scheduleService.setProcessing(true, message: 'AI 正在分析日程信息...', progress: 0.7);

      // 适配点：传入 Token 供后端代理
      final dynamic llmResult = await _llmService.sendToBot(
        ocrResult, 
        token: authService.user?.token
      );

      if (!mounted) return;
      scheduleService.setProcessing(false);

      List<Schedule> parsedSchedules = [];
      if (llmResult is List) {
        parsedSchedules = llmResult.map((data) => _mapToSchedule(data)).toList();
      } else if (llmResult is Map<String, dynamic>) {
        parsedSchedules = [_mapToSchedule(llmResult)];
      } else {
        throw llmResult.toString();
      }

      if (parsedSchedules.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OcrConfirmPage(
              initialSchedules: parsedSchedules,
            ),
          ),
        );
      } else {
        throw "未能提取到有效的日程";
      }
    } catch (e) {
      if (mounted) {
        scheduleService.setProcessing(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Schedule _mapToSchedule(Map<String, dynamic> data) {
    final String title = data['title'] ?? '分享导入的日程';
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

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: _buildSearchBox(),
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              color: Colors.white,
              onSelected: (value) {
                if (value == 'sync') {
                  final auth = context.read<AuthService>();
                  final schedule = context.read<ScheduleService>();
                  if (auth.isAuthenticated) {
                    schedule.syncWithCloud(auth.user?.token);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请先登录后再同步')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.more_vert, color: AppColors.textMain),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupItem('sync', Icons.cloud_sync_outlined, '云端同步'),
              ],
            ),
            const SizedBox(width: 8),
          ],
        );
      case 1:
        return AppBar(
          title: const Text('功能广场'),
          backgroundColor: AppColors.background,
          elevation: 0,
        );
      default:
        return null;
    }
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String title) {
    return PopupMenuItem<String>(
      value: value,
      height: 45,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(width: 12),
            Icon(Icons.search, size: 20, color: AppColors.textGrey),
            SizedBox(width: 8),
            Text(
              '搜索标题、描述或地点',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          if (scheduleService.isProcessing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildProcessingBar(scheduleService),
            ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                final selectedDate = context.read<ScheduleService>().selectedDate;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSchedulePage(initialDate: selectedDate),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              elevation: 2,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProcessingBar(ScheduleService service) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.processingMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (service.processingProgress != null)
                Text(
                  '${(service.processingProgress! * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          if (service.processingProgress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: service.processingProgress,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: AppColors.cardBackground,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
