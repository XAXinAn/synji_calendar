import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/app_constants.dart';

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  late final Dio _dio;
  late final CookieJar _cookieJar;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _cookieJar = CookieJar();
    _initDio();
    _loadUser();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl, 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      contentType: 'application/json',
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_user?.token != null && _user!.token.isNotEmpty) {
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
          } catch (refreshError) {}
          logout(); 
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> updateProfile({required String nickname}) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.patch('/auth/me', data: {
        'nickname': nickname,
      });
      if (response.data['code'] == 200) {
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
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      } catch (e) {}
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
      throw Exception(e.response?.data?['message'] ?? '服务器连接异常');
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
        if (response.data['data'] != null && response.data['data']['token'] != null) {
          _user = User.fromJson(response.data['data']);
          await _saveUserToPrefs();
        } else {
          return await login(username, password);
        }
        return true;
      } else {
        throw Exception(response.data['message'] ?? '注册失败');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? '注册异常');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_user != null) await _dio.post('/auth/logout');
    } catch (e) {} finally {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('last_sync_timestamp');
      _cookieJar.deleteAll();
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.delete('/auth/me');
      if (response.data['code'] == 200) {
        await logout();
        return true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> _saveUserToPrefs() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await _dio.post('/auth/refresh');
      if (response.data['code'] == 200) {
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
    } catch (e) {}
    return false;
  }
}
