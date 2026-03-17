import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/schedule.dart';
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
      baseUrl: 'http://localhost:8080/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ));
  }

  // 1. 获取云端列表 (仅用于预览管理)
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

  // 2. 删除单个云端记录 (不影响本地)
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

  // 3. 核心同步逻辑 (镜像上传 + 增量下载)
  Future<void> syncWithCloud(String? token) async {
    if (token == null) return;
    
    setProcessing(true, message: '正在同步云端数据...');
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';

      // 【上传】以本地为准，更新云端镜像
      final localSchedules = await _dbHelper.getSchedules();
      await _dio.post('/schedules/sync', data: localSchedules.map((e) => e.toMap()).toList());

      // 【拉取】获取云端可能存在的、由其他设备同步的数据
      final response = await _dio.get('/schedules');
      if (response.data['code'] == 200) {
        final List<dynamic> remoteData = response.data['data'];
        final remoteSchedules = remoteData.map((e) => Schedule.fromMap(e)).toList();

        // 【安全合并】不再清空本地，而是采用 insert/update 覆盖模式
        // 这样如果云端被清空，本地数据依然存在
        for (var s in remoteSchedules) {
          await _dbHelper.insertSchedule(s);
        }
        
        await loadSchedules();
      }
      setProcessing(false);
    } catch (e) {
      _logger.e('同步失败: $e');
      setProcessing(false, message: '同步失败: 网络异常');
    }
  }

  // 4. 清空云端备份 (绝不影响本地)
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
      final data = await _dbHelper.getSchedules();
      _schedules.clear();
      _schedules.addAll(data);
      _sortSchedules();
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to load schedules: $e');
    }
  }

  void _sortSchedules() {
    _schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _dbHelper.insertSchedule(schedule);
      _schedules.add(schedule);
      _sortSchedules();
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to add schedule: $e');
    }
  }

  Future<void> updateSchedule(Schedule updatedSchedule) async {
    try {
      await _dbHelper.updateSchedule(updatedSchedule);
      final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
      if (index != -1) {
        _schedules[index] = updatedSchedule;
        _sortSchedules();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to update schedule: $e');
    }
  }

  Future<void> removeSchedule(String id) async {
    try {
      await _dbHelper.deleteSchedule(id);
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to remove schedule: $e');
    }
  }

  List<Schedule> getSchedulesForDay(DateTime day) {
    return _schedules.where((s) {
      return s.dateTime.year == day.year &&
          s.dateTime.month == day.month &&
          s.dateTime.day == day.day;
    }).toList();
  }
}
