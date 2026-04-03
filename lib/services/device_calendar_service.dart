import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule.dart';

class DeviceCalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// 检查并请求日历权限
  /// 优化：兼容 Android 14+ 的 Full Access 和旧版本的通用日历权限
  Future<bool> requestPermissions() async {
    // 1. 优先尝试请求 Full Access (针对 Android 14+)
    var status = await Permission.calendarFullAccess.status;
    if (status.isGranted) return true;

    if (status.isDenied || status.isLimited) {
      status = await Permission.calendarFullAccess.request();
    }

    // 2. 如果 Full Access 未被授予，尝试通用的 Calendar 权限 (兼容旧版本或特定厂商)
    if (!status.isGranted) {
      status = await Permission.calendar.status;
      if (status.isDenied) {
        status = await Permission.calendar.request();
      }
    }

    return status.isGranted;
  }

  /// 获取系统日历列表
  Future<List<Calendar>> getCalendars() async {
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      debugPrint('获取日历失败：未授予权限');
      return [];
    }

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    return calendarsResult.data ?? [];
  }

  /// 将应用内的日程同步到系统日历
  Future<bool> addToDeviceCalendar(Schedule schedule) async {
    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        debugPrint('写入日历失败：权限不足');
        return false;
      }

      // 1. 获取所有日历
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      final calendars = calendarsResult.data;
      if (calendars == null || calendars.isEmpty) {
        debugPrint('写入日历失败：找不到可用的系统日历');
        return false;
      }

      // 2. 寻找第一个可写的日历
      Calendar? targetCalendar;
      for (var cal in calendars) {
        if (cal.isReadOnly == false) {
          targetCalendar = cal;
          break;
        }
      }

      if (targetCalendar == null || targetCalendar.id == null) {
        debugPrint('写入日历失败：未找到可写的日历账号');
        return false;
      }

      // 3. 创建系统日历事件
      final event = Event(
        targetCalendar.id,
        title: schedule.title,
        description: schedule.description,
        start: TZDateTime.from(schedule.dateTime, local),
        end: TZDateTime.from(
          schedule.dateTime.add(const Duration(hours: 1)),
          local,
        ),
        location: schedule.location,
      );

      // 4. 保存
      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (createEventResult?.isSuccess == true) {
        debugPrint('成功同步到系统日历: ${schedule.title}');
        return true;
      } else {
        // 彻底解决编译错误：直接打印错误对象
        final errors = createEventResult?.errors;
        debugPrint('写入系统日历失败: $errors');
        return false;
      }
    } catch (e) {
      debugPrint('写入系统日历抛出异常: $e');
      return false;
    }
  }

  /// 批量同步所有日程到系统日历
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
