import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/schedule.dart';
import '../utils/app_constants.dart';
import 'database_helper.dart';

class ScheduleService extends ChangeNotifier {
  final List<Schedule> _schedules = [];
  final Logger _logger = Logger();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final Dio _dio;
  
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isProcessing = false;
  String _processingMessage = '';
  double? _processingProgress;

  bool get isProcessing => _isProcessing;
  String get processingMessage => _processingMessage;
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
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ));
  }

  // 1. 获取云端列表 (仅个人日程)
  Future<List<Schedule>> fetchCloudSchedules(String? token) async {
    if (token == null) return [];
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/schedules');
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => Schedule.fromMap(e)).toList();
      }
    } catch (e) {
      _logger.e('获取云端列表失败: $e');
    }
    return [];
  }

  // 2. 删除个人云端记录
  Future<bool> deleteSingleCloudSchedule(String? token, String id) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.delete('/schedules/$id');
      return response.data['code'] == 200;
    } catch (e) {
      _logger.e('删除云端日程失败: $e');
      return false;
    }
  }

  // 3. 核心同步逻辑 (仅针对个人日程)
  Future<void> syncWithCloud(String? token) async {
    if (token == null) return;
    
    setProcessing(true, message: '正在同步个人云端数据...');
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';

      // 【上传】仅上传本地个人日程
      final localSchedules = await _dbHelper.getSchedules();
      final personalSchedules = localSchedules.where((s) => s.groupId == null || s.groupId!.isEmpty).toList();
      await _dio.post('/schedules/sync', data: personalSchedules.map((e) => e.toMap()).toList());

      // 【拉取】仅拉取个人日程
      final response = await _dio.get('/schedules');
      if (response.data['code'] == 200) {
        final List<dynamic> remoteData = response.data['data'];
        final remoteSchedules = remoteData.map((e) => Schedule.fromMap(e)).toList();
        
        // 核心改动：同步前先清理本地个人日程，防止重复
        // 或者使用 insert (replace 模式)
        for (var s in remoteSchedules) {
          await _dbHelper.insertSchedule(s);
        }
      }
      
      await loadSchedules();
      setProcessing(false);
    } catch (e) {
      _logger.e('同步失败: $e');
      setProcessing(false, message: '同步失败: 网络异常');
    }
  }

  // 4. 清空云端备份
  Future<bool> clearCloudSchedules(String? token) async {
    if (token == null) return false;
    
    setProcessing(true, message: '正在清空云端备份...');
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.delete('/schedules/clear');
      setProcessing(false);
      return response.data['code'] == 200;
    } catch (e) {
      _logger.e('清空云端失败: $e');
      setProcessing(false);
      return false;
    }
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

  Future<void> loadSchedules() async {
    try {
      // 核心改动：loadSchedules 仅加载本地个人日程
      final data = await _dbHelper.getSchedules();
      _schedules.clear();
      _schedules.addAll(data.where((s) => s.groupId == null || s.groupId!.isEmpty));
      _sortSchedules();
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to load schedules: $e');
    }
  }

  void _sortSchedules() {
    _schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // 修改：addSchedule 区分个人和小组
  Future<void> addSchedule(Schedule schedule, {String? token}) async {
    try {
      if (schedule.groupId == null || schedule.groupId!.isEmpty) {
        // 个人日程：本地优先
        await _dbHelper.insertSchedule(schedule);
        _schedules.add(schedule);
        _sortSchedules();
        notifyListeners();
      } else {
        // 小组日程：纯云端，不存本地库
        if (token != null) {
          _dio.options.headers['Authorization'] = 'Bearer $token';
          await _dio.post('/groups/${schedule.groupId}/schedules', data: schedule.toMap());
        } else {
          throw Exception('登录已过期，无法发布小组日程');
        }
      }
    } catch (e) {
      _logger.e('Failed to add schedule: $e');
      rethrow;
    }
  }

  // 修改：updateSchedule 区分个人和小组
  Future<void> updateSchedule(Schedule updatedSchedule, {String? token}) async {
    try {
      if (updatedSchedule.groupId == null || updatedSchedule.groupId!.isEmpty) {
        // 个人日程：更新本地
        await _dbHelper.updateSchedule(updatedSchedule);
        final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
        if (index != -1) {
          _schedules[index] = updatedSchedule;
          _sortSchedules();
          notifyListeners();
        }
      } else {
        // 小组日程：仅同步云端
        if (token != null) {
          _dio.options.headers['Authorization'] = 'Bearer $token';
          await _dio.post('/groups/${updatedSchedule.groupId}/schedules', data: updatedSchedule.toMap());
        }
      }
    } catch (e) {
      _logger.e('Failed to update schedule: $e');
      rethrow;
    }
  }

  // 修改：removeSchedule 区分个人和小组
  Future<void> removeSchedule(String id, {String? token, String? groupId}) async {
    try {
      if (groupId == null || groupId.isEmpty) {
        // 个人日程：本地删除
        await _dbHelper.deleteSchedule(id);
        _schedules.removeWhere((s) => s.id == id);
        notifyListeners();
      } else {
        // 小组日程：云端删除
        if (token != null) {
          _dio.options.headers['Authorization'] = 'Bearer $token';
          await _dio.delete('/groups/$groupId/schedules/$id');
        }
      }
    } catch (e) {
      _logger.e('Failed to remove schedule: $e');
    }
  }

  List<Schedule> getSchedulesForDay(DateTime day) {
    // 这里仅返回个人日程
    return _schedules.where((s) {
      return s.dateTime.year == day.year &&
          s.dateTime.month == day.month &&
          s.dateTime.day == day.day;
    }).toList();
  }
}
