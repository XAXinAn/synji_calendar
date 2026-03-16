import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/schedule.dart';
import 'database_helper.dart';

class ScheduleService extends ChangeNotifier {
  final List<Schedule> _schedules = [];
  final Logger _logger = Logger();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // 新增：记录当前选中的日期，默认为今天
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<Schedule> get schedules => List.unmodifiable(_schedules);

  ScheduleService() {
    loadSchedules();
  }

  // 新增：更新选中日期的方法
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
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
