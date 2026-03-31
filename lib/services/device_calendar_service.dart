import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule.dart';

class DeviceCalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// 检查并请求日历权限
  Future<bool> requestPermissions() async {
    var status = await Permission.calendarFullAccess.status;
    if (status.isGranted) return true;

    if (status.isDenied || status.isLimited) {
      status = await Permission.calendarFullAccess.request();
    }

    return status.isGranted;
  }

  /// 获取系统日历列表
  Future<List<Calendar>> getCalendars() async {
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) return [];

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    return calendarsResult.data ?? [];
  }

  /// 将应用内的日程同步到系统日历
  Future<bool> addToDeviceCalendar(Schedule schedule) async {
    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) return false;

      // 1. 获取所有日历，默认使用第一个可写的日历
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final calendars = calendarsResult.data;
      if (calendars == null || calendars.isEmpty) return false;

      // 优先寻找名字里带 "Calendar" 或 "Google" 的，或者找第一个不是只读的
      Calendar? targetCalendar;
      for (var cal in calendars) {
        if (cal.isReadOnly == false) {
          targetCalendar = cal;
          break;
        }
      }

      if (targetCalendar == null || targetCalendar.id == null) return false;

      // 2. 创建系统日历事件
      // 这里的 TZDateTime 需要处理时区，简单起见我们基于当前时区
      final event = Event(
        targetCalendar.id,
        title: schedule.title,
        description: schedule.description,
        start: TZDateTime.from(schedule.dateTime, local),
        end: TZDateTime.from(
          schedule.dateTime.add(const Duration(hours: 1)), // 默认一小时
          local,
        ),
        location: schedule.location,
      );

      // 3. 保存
      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      return createEventResult?.isSuccess ?? false;
    } catch (e) {
      debugPrint('写入系统日历失败: $e');
      return false;
    }
  }

  /// 批量同步所有日程到系统日历 (可选功能)
  Future<int> syncAllToDevice(List<Schedule> schedules) async {
    int successCount = 0;
    for (var s in schedules) {
      if (await addToDeviceCalendar(s)) {
        successCount++;
      }
    }
    return successCount;
  }
}
