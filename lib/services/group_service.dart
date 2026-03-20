import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/schedule.dart';
import '../utils/app_constants.dart';

class GroupService extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    contentType: 'application/json',
  ));

  List<Group> _myGroups = [];
  bool _isLoading = false;

  List<Group> get myGroups => _myGroups;
  bool get isLoading => _isLoading;

  // 获取我加入的小组
  Future<void> fetchMyGroups(String? token) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/groups');
      if (response.data['code'] == 200) {
        final List data = response.data['data'];
        _myGroups = data.map((e) => Group.fromMap(e)).toList();
      }
    } catch (e) {
      debugPrint('获取小组失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取小组内成员列表
  Future<List<GroupMember>> fetchGroupMembers(String groupId, String? token) async {
    if (token == null) return [];
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/groups/$groupId/members');
      if (response.data['code'] == 200) {
        final List data = response.data['data'];
        return data.map((e) => GroupMember.fromMap(e)).toList();
      }
    } catch (e) {
      debugPrint('获取小组成员失败: $e');
    }
    return [];
  }

  // 设置/取消管理员 (最多2个管理员)
  Future<bool> toggleAdmin(String groupId, String memberId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups/$groupId/admins', data: {
        'memberId': memberId,
      });
      if (response.data['code'] == 200) {
        await fetchMyGroups(token); // 刷新小组状态
        return true;
      }
    } catch (e) {
      debugPrint('设置管理员失败: $e');
    }
    return false;
  }

  // 创建小组
  Future<bool> createGroup(String name, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups', data: {'name': name});
      if (response.data['code'] == 200) {
        await fetchMyGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('创建小组失败: $e');
    }
    return false;
  }

  // 加入小组
  Future<bool> joinGroup(String inviteCode, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
      if (response.data['code'] == 200) {
        await fetchMyGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('加入小组失败: $e');
    }
    return false;
  }

  // 获取小组共享日程
  Future<List<Schedule>> fetchGroupSchedules(String groupId, String? token) async {
    if (token == null) return [];
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/groups/$groupId/schedules');
      if (response.data['code'] == 200) {
        final List data = response.data['data'];
        // 后端 5.6 返回的是 GroupScheduleDto，字段包含 dateTime
        return data.map((e) => Schedule.fromMap(e)).toList();
      }
    } catch (e) {
      debugPrint('获取小组日程失败: $e');
    }
    return [];
  }

  // 创建小组共享日程 (5.7)
  Future<Schedule?> createGroupSchedule(String groupId, Schedule schedule, String? token) async {
    if (token == null) return null;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post(
        '/groups/$groupId/schedules',
        data: {
          'title': schedule.title,
          'description': schedule.description,
          'dateTime': schedule.dateTime.toIso8601String(),
          'location': schedule.location,
        },
      );
      if (response.data['code'] == 200) {
        return Schedule.fromMap(response.data['data']);
      }
    } catch (e) {
      debugPrint('创建小组日程失败: $e');
    }
    return null;
  }

  // 更新小组共享日程 (5.8)
  Future<Schedule?> updateGroupSchedule(String groupId, Schedule schedule, String? token) async {
    if (token == null) return null;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.put(
        '/groups/$groupId/schedules/${schedule.id}',
        data: {
          'title': schedule.title,
          'description': schedule.description,
          'dateTime': schedule.dateTime.toIso8601String(),
          'location': schedule.location,
        },
      );
      if (response.data['code'] == 200) {
        return Schedule.fromMap(response.data['data']);
      }
    } catch (e) {
      debugPrint('更新小组日程失败: $e');
    }
    return null;
  }

  // 删除小组共享日程 (5.9)
  Future<bool> deleteGroupSchedule(String groupId, String scheduleId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.delete('/groups/$groupId/schedules/$scheduleId');
      return response.data['code'] == 200;
    } catch (e) {
      debugPrint('删除小组日程失败: $e');
      return false;
    }
  }

  // 解散小组 (仅创建者)
  Future<bool> deleteGroup(String groupId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.delete('/groups/$groupId');
      // 注意：某些后端 API 规范可能要求 code 为 200 才算成功
      if (response.data['code'] == 200 || response.statusCode == 200) {
        await fetchMyGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('解散小组失败: $e');
    }
    return false;
  }

  // 退出小组 (非创建者)
  Future<bool> quitGroup(String groupId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      // 检查路径是否正确，根据文档规范，退出小组通常是 POST 或 DELETE
      final response = await _dio.post('/groups/$groupId/quit');
      if (response.data['code'] == 200 || response.statusCode == 200) {
        await fetchMyGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('退出小组失败: $e');
    }
    return false;
  }
}
