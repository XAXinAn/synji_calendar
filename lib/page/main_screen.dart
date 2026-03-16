import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:synji_calendar/utils/app_constants.dart';
import '../services/schedule_service.dart';
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

    try {
      final file = File(cleanPath);
      if (!await file.exists()) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 16),
              Text('AI 正在识别分享的内容...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );

      final String ocrResult = await _ocrService.processImage(cleanPath);
      if (ocrResult.trim().isEmpty) throw "未能识别到图片中的文字";

      final dynamic llmResult = await _llmService.sendToBot(ocrResult);

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

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
        ScaffoldMessenger.of(context).clearSnackBars();
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
                if (value == 'import') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('导入功能开发中...')),
                  );
                }
              },
              icon: const Icon(Icons.more_vert, color: AppColors.textMain),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupItem('import', Icons.file_download_outlined, '日历导入'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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
