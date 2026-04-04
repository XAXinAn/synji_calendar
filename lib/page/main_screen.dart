import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'privacy_policy_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  StreamSubscription? _intentDataStreamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
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
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyPolicy();
      _initSharingIntent();
      _initConnectivityListener();
      _autoSync();
    });
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected =
          results.any((result) => result != ConnectivityResult.none);
      if (isConnected) {
        _autoSync();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoSync();
    }
  }

  void _autoSync() {
    final auth = context.read<AuthService>();
    if (auth.isAuthenticated) {
      context
          .read<ScheduleService>()
          .syncWithCloud(auth.user?.token, silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentDataStreamSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _checkPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasAgreed = prefs.getBool('privacy_policy_agreed') ?? false;
    if (!hasAgreed && mounted) _showPrivacyDialog();
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(
              child: Text('温馨提示',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: AppColors.textMain, fontSize: 14, height: 1.6),
                children: [
                  const TextSpan(
                      text: '欢迎您使用讯极日历！我们非常重视您的个人信息和隐私保护。在您使用服务之前，请仔细阅读'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacyPolicyPage()));
                      },
                  ),
                  const TextSpan(
                      text: '。我们将按照您的授权来处理您的信息，为您提供日程同步、AI解析等服务。\n\n'),
                  const TextSpan(
                      text: '1. 为了更好的向您提供注册认证、发布信息等功能，我们会收集、使用必要的信息；\n'),
                  const TextSpan(text: '2. 基于您的授权我们可能会获取您的相机、相册等权限。'),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('privacy_policy_agreed', true);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('同意并进入',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => exit(0),
                    child: const Text('不同意并退出',
                        style: TextStyle(color: AppColors.textGrey))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _initSharingIntent() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedImages(value);
    }, onError: (err) => debugPrint("getMediaStream error: $err"));

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) _handleSharedImages(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedImages(List<SharedMediaFile> files) async {
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();
    final List<Schedule> allParsedSchedules = [];
    int failedCount = 0;

    try {
      for (int i = 0; i < files.length; i++) {
        try {
          final String path = OCRService.normalizePath(files[i].path);

          if (OCRService.isPhotosAssetUri(path) ||
              !OCRService.isLikelyImagePath(path) ||
              !await File(path).exists()) {
            failedCount++;
            continue;
          }

          final double step = 1.0 / files.length;
          scheduleService.setProcessing(
            true,
            message: '正在识别 (${i + 1}/${files.length})...',
            progress: i * step + (step * 0.3),
          );

          final String ocrResult = await _ocrService.processImage(path);
          if (ocrResult.trim().isEmpty) {
            failedCount++;
            continue;
          }

          scheduleService.setProcessing(
            true,
            message: 'AI 解析中 (${i + 1}/${files.length})...',
            progress: i * step + (step * 0.8),
          );

          final dynamic llmResult =
              await _llmService.sendToBot(ocrResult, token: authService.user?.token);

          if (llmResult is List) {
            allParsedSchedules.addAll(llmResult.map((data) => _mapToSchedule(data, i)));
          } else if (llmResult is Map<String, dynamic>) {
            allParsedSchedules.add(_mapToSchedule(llmResult, i));
          } else {
            failedCount++;
          }
        } catch (_) {
          failedCount++;
        }
      }

      scheduleService.setProcessing(false);

      if (failedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('有 $failedCount 张图片处理失败，请在应用内重新选择后重试'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (allParsedSchedules.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OcrConfirmPage(initialSchedules: allParsedSchedules),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scheduleService.setProcessing(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Schedule _mapToSchedule(Map<String, dynamic> data, int index) {
    DateTime dateTime = DateTime.now();
    try {
      if (data['time'] != null) dateTime = DateTime.parse(data['time']);
    } catch (_) {}
    return Schedule(
      id: '${DateTime.now().millisecondsSinceEpoch}_$index',
      title: data['title'] ?? '未命名日程',
      description: data['description'],
      dateTime: dateTime,
      location: data['location'],
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_selectedIndex != 0 && _selectedIndex != 1) return null;
    return AppBar(
      title: _selectedIndex == 0 ? _buildSearchBox() : const Text('功能广场'),
      backgroundColor: AppColors.background,
      elevation: 0,
    );
  }

  Widget _buildSearchBox() {
    final scheduleService = context.watch<ScheduleService>();
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => const SearchPage())),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 20, color: AppColors.textGrey),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('搜索日程、小组或邀请码',
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                    overflow: TextOverflow.ellipsis)),
            _buildSyncIndicator(scheduleService.syncStatus),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIndicator(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
      case SyncStatus.success:
        return const Icon(Icons.cloud_done, size: 16, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, size: 16, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          if (scheduleService.isProcessing)
            Positioned(
                left: 16,
                right: 16,
                top: 8,
                child: _buildProcessingBar(scheduleService)),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddSchedulePage(
                          initialDate:
                              context.read<ScheduleService>().selectedDate))),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary))),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(service.processingMessage,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
              if (service.processingProgress != null)
                Text('${(service.processingProgress! * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
          if (service.processingProgress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                    value: service.processingProgress,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    minHeight: 3)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: AppColors.cardBackground,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页'),
        BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: '发现'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey,
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
    );
  }
}
