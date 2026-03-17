import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  late final Dio _dio;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _initDio();
    _loadUser();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/v1', 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_user?.token != null) {
          options.headers['Authorization'] = 'Bearer ${_user!.token}';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && _user != null) {
          try {
            final success = await _refreshToken();
            if (success) {
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${_user!.token}';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (refreshError) {
            debugPrint('Token 刷新失败: $refreshError');
          }
          logout();
        }
        return handler.next(e);
      },
    ));
  }

  // 更新个人资料接口
  Future<bool> updateProfile({required String nickname}) async {
    if (_user == null) return false;
    
    try {
      final response = await _dio.patch('/auth/me', data: {
        'nickname': nickname,
      });

      if (response.data['code'] == 200) {
        // 更新本地内存中的用户对象，同时保留原有的 token
        _user = User(
          id: _user!.id,
          username: _user!.username,
          nickname: nickname,
          token: _user!.token,
        );
        await _saveUserToPrefs();
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      debugPrint('资料更新失败: ${e.message}');
      rethrow;
    }
    return false;
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
        _syncUserInfo();
      } catch (e) {
        debugPrint('加载本地用户信息失败: $e');
      }
    }
  }

  Future<void> _syncUserInfo() async {
    if (_user == null) return;
    try {
      final response = await _dio.get('/auth/me');
      if (response.data['code'] == 200) {
        final token = _user!.token;
        _user = User.fromJson({
          ...response.data['data'],
          'token': token,
        });
        _saveUserToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('用户信息同步失败: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      if (response.data['code'] == 200) {
        _user = User.fromJson(response.data['data']);
        await _saveUserToPrefs();
        return true;
      } else {
        throw Exception(response.data['message'] ?? '登录失败');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? '本地服务器连接异常');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
      });
      if (response.data['code'] == 200 || response.data['code'] == 201) {
        _user = User.fromJson(response.data['data']);
        await _saveUserToPrefs();
        return true;
      } else {
        throw Exception(response.data['message'] ?? '注册失败');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? '本地注册失败');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await _dio.post('/auth/refresh');
      if (response.data['code'] == 200) {
        // 兼容取值逻辑：支持 token 或 accessToken 字段
        final newToken = response.data['data']['token'] ?? response.data['data']['accessToken'];
        if (newToken != null) {
          _user = User(
            id: _user!.id,
            username: _user!.username,
            nickname: _user!.nickname,
            token: newToken,
          );
          await _saveUserToPrefs();
          return true;
        }
      }
    } catch (e) {
      debugPrint('本地 Token 刷新异常: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      if (_user != null) await _dio.post('/auth/logout');
    } finally {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    }
  }
}
