import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
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

  Future<List<GroupMember>> fetchGroupMembers(String groupId, String? token) async {
    if (token == null) return [];
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('/groups/$groupId/members');
      if (response.data['code'] == 200) {
        final List data = response.data['data'];
        return data.map((e) => GroupMember.fromMap(e)).toList();
      }
    } catch (e) {}
    return [];
  }

  // 【补回】管理员切换方法
  Future<bool> toggleAdmin(String groupId, String memberId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups/$groupId/admins', data: {
        'memberId': memberId,
      });
      if (response.data['code'] == 200) {
        await fetchMyGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('设置管理员失败: $e');
    }
    return false;
  }

  Future<bool> createGroup(String name, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups', data: {'name': name});
      if (response.data['code'] == 200) { await fetchMyGroups(token); return true; }
    } catch (e) {}
    return false;
  }

  Future<bool> joinGroup(String inviteCode, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
      if (response.data['code'] == 200) { await fetchMyGroups(token); return true; }
    } catch (e) {}
    return false;
  }

  Future<bool> deleteGroup(String groupId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.delete('/groups/$groupId');
      if (response.data['code'] == 200) { await fetchMyGroups(token); return true; }
    } catch (e) {}
    return false;
  }

  Future<bool> quitGroup(String groupId, String? token) async {
    if (token == null) return false;
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.post('/groups/$groupId/quit');
      if (response.data['code'] == 200) { await fetchMyGroups(token); return true; }
    } catch (e) {}
    return false;
  }
}
