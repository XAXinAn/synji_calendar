import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../utils/app_constants.dart';
import 'database_helper.dart';

enum SyncStatus { idle, syncing, error, success }

class ScheduleService extends ChangeNotifier {
  final List<Schedule> _schedules = [];
  final Logger _logger = Logger();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final Dio _dio;
  
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  String _processingMessage = '';
  String get processingMessage => _processingMessage;
  double? _processingProgress;
  double? get processingProgress => _processingProgress;

  List<Schedule> get schedules => List.unmodifiable(_schedules);

  ScheduleService() {
    _initDio();
    loadSchedules();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('🌐 [Network] $obj'),
    ));
  }

  Future<void> clearLocalData() async {
    _schedules.clear();
    await _dbHelper.clearAllSchedules();
    notifyListeners();
  }

  Future<String?> _getSafeToken(String? providedToken) async {
    if (providedToken != null && providedToken.isNotEmpty) return providedToken;
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      return userData['token'];
    }
    return null;
  }

  /// 统一数据加载：从本地数据库读取并刷新内存列表
  Future<void> loadSchedules() async {
    try {
      final data = await _dbHelper.getActiveSchedules();
      _schedules.clear();
      // 终极防线：再次确保内存中没有 isDeleted 的数据
      _schedules.addAll(data.where((s) => !s.isDeleted));
      _schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
    } catch (e) {
      _logger.e('loadSchedules error: $e');
    }
  }

  /// 全量/增量同步逻辑 (主要用于个人日程后台同步和小组日程下行拉取)
  Future<void> syncWithCloud(String? token, {bool silent = false}) async {
    String? effectiveToken = await _getSafeToken(token);
    if (effectiveToken == null || _syncStatus == SyncStatus.syncing) return;
    
    _syncStatus = SyncStatus.syncing;
    if (!silent) setProcessing(true, message: '同步中...');
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_sync_timestamp');
      final lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.fromMillisecondsSinceEpoch(0);
      
      _dio.options.headers['Authorization'] = 'Bearer $effectiveToken';

      // 1. 上行 (Push) - 仅推本地个人日程变动
      final dirtySchedules = await _dbHelper.getDirtySchedules(lastSyncTime);
      if (dirtySchedules.isNotEmpty) {
        final syncPayload = {
          "client_sync_time": DateTime.now().toUtc().toIso8601String(),
          "changes": dirtySchedules.map((e) => e.toMap()).toList(),
        };
        await _dio.post('/schedules/delta-sync', data: syncPayload);
      }

      // 2. 下行 (Fetch) - 拉取云端所有变动（含小组日程）
      final response = await _dio.get('/schedules/delta-fetch', queryParameters: {'since': lastSyncTime.toUtc().toIso8601String()});
      if (response.data['code'] == 200) {
        final List<dynamic> remoteData = response.data['data'] ?? [];
        for (var item in remoteData) {
          final s = Schedule.fromMap(item);
          if (s.isDeleted) {
            await _dbHelper.physicalDelete(s.id);
          } else {
            await _dbHelper.insertSchedule(s);
          }
        }
      }
      
      await prefs.setString('last_sync_timestamp', DateTime.now().toUtc().toIso8601String());
      await loadSchedules();
      
      _syncStatus = SyncStatus.success;
      if (!silent) setProcessing(false);
      Future.delayed(const Duration(seconds: 1), () => _resetSyncStatus());
    } catch (e) {
      _handleSyncError(e, silent);
    }
  }

  // --- 重构后的 CRUD：严格区分小组与个人 ---

  Future<void> addSchedule(Schedule schedule, {String? token}) async {
    if (schedule.groupId != null && schedule.groupId!.isNotEmpty) {
      // 小组日程：必须先成功同步云端
      await _groupDirectSync(schedule, token, isDelete: false);
    } else {
      // 个人日程：本地优先
      final newSchedule = schedule.copyWith(updatedAt: DateTime.now(), isDeleted: false);
      await _dbHelper.insertSchedule(newSchedule);
      await loadSchedules();
      syncWithCloud(token, silent: true);
    }
  }

  Future<void> updateSchedule(Schedule schedule, {String? token}) async {
    if (schedule.groupId != null && schedule.groupId!.isNotEmpty) {
      // 小组日程：必须先成功同步云端
      await _groupDirectSync(schedule, token, isDelete: false);
    } else {
      // 个人日程：本地优先
      final updated = schedule.copyWith(updatedAt: DateTime.now(), isDeleted: false);
      await _dbHelper.insertSchedule(updated);
      await loadSchedules();
      syncWithCloud(token, silent: true);
    }
  }

  Future<void> removeSchedule(String id, {String? token}) async {
    // 强制从底层查，不分活跃状态
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('schedules', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return;
    
    final target = Schedule.fromMap(maps.first);
    if (target.groupId != null && target.groupId!.isNotEmpty) {
      // 小组日程：强一致性云端物理删除
      await _groupDirectSync(target, token, isDelete: true);
    } else {
      // 个人日程：本地逻辑删除
      await _dbHelper.markAsDeleted(id);
      await loadSchedules();
      syncWithCloud(token, silent: true);
    }
  }

  /// 【小组专用】直接同步逻辑：成功后才更新本地显示，删除则彻底抹除
  Future<void> _groupDirectSync(Schedule schedule, String? token, {required bool isDelete}) async {
    String? effectiveToken = await _getSafeToken(token);
    if (effectiveToken == null) throw Exception('请登录后操作小组日程');

    setProcessing(true, message: isDelete ? '正在同步云端删除...' : '正在同步小组日程...');
    try {
      _dio.options.headers['Authorization'] = 'Bearer $effectiveToken';
      final syncTime = DateTime.now().toUtc().toIso8601String();
      
      final syncPayload = {
        "client_sync_time": syncTime,
        "changes": [
          {
            ...schedule.toMap(),
            "isDeleted": isDelete ? 1 : 0,
            "updatedAt": syncTime,
          }
        ]
      };
      
      final response = await _dio.post('/schedules/delta-sync', data: syncPayload);
      if (response.data['code'] == 200) {
        if (isDelete) {
          // 云端删除成功 -> 本地物理抹除 -> 彻底不可见
          await _dbHelper.physicalDelete(schedule.id);
        } else {
          // 云端保存成功 -> 更新本地显示缓存
          await _dbHelper.insertSchedule(schedule.copyWith(updatedAt: DateTime.now()));
        }
        await loadSchedules();
        setProcessing(false);
      } else {
        throw Exception(response.data['message'] ?? '操作失败');
      }
    } on DioException catch (e) {
      setProcessing(false);
      String msg = e.response?.data?['message'] ?? '网络请求失败';
      if (e.response?.statusCode == 403) msg = '权限不足：只有管理员可操作此小组日程';
      throw Exception(msg);
    }
  }

  /// 【专为小组页面设计】从云端拉取并刷新特定小组数据
  Future<List<Schedule>> fetchGroupSchedulesDirect(String groupId, String? token) async {
    String? effectiveToken = await _getSafeToken(token);
    if (effectiveToken == null) return [];

    try {
      _dio.options.headers['Authorization'] = 'Bearer $effectiveToken';
      // 注意：这里直接调用后端的按小组查询接口，或者复用同步接口
      final response = await _dio.get('/groups/$groupId/schedules');
      if (response.data['code'] == 200) {
        final List data = response.data['data'] ?? [];
        final List<Schedule> list = [];
        for (var item in data) {
          final s = Schedule.fromMap(item);
          if (s.isDeleted) {
            await _dbHelper.physicalDelete(s.id);
          } else {
            await _dbHelper.insertSchedule(s);
            list.add(s);
          }
        }
        await loadSchedules();
        return list;
      }
    } catch (e) {
      debugPrint('fetchGroupSchedulesDirect error: $e');
    }
    // 降级：从本地已加载的数据中过滤
    return _schedules.where((s) => s.groupId == groupId).toList();
  }

  // --- 工具方法 ---

  void _resetSyncStatus() {
    _syncStatus = SyncStatus.idle;
    notifyListeners();
  }

  void _handleSyncError(dynamic e, bool silent) {
    _syncStatus = SyncStatus.error;
    if (!silent) setProcessing(false);
    notifyListeners();
  }

  List<Schedule> getSchedulesForDay(DateTime day) {
    return _schedules.where((s) {
      return s.dateTime.year == day.year &&
          s.dateTime.month == day.month &&
          s.dateTime.day == day.day;
    }).toList();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setProcessing(bool processing, {String message = '', double? progress}) {
    _isProcessing = processing;
    _processingMessage = message;
    _processingProgress = progress;
    notifyListeners();
  }
}
