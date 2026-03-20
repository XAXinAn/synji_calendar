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

    // 添加 Cookie 管理器，处理后端 HttpOnly 的 refreshToken
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_user?.token != null && _user!.token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${_user!.token}';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 401 且有用户登录态时尝试刷新 Token
        if (e.response?.statusCode == 401 && _user != null) {
          try {
            // 注意：/auth/refresh 不需要手动带 Token，它通过 Cookie 带 refreshToken
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
          logout(); // 刷新失败则强制退出
        }
        return handler.next(e);
      },
    ));
  }

  // 更新个人资料
  Future<bool> updateProfile({required String nickname}) async {
    if (_user == null) return false;
    
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
        final currentToken = _user!.token;
        // 使用后端返回的数据更新，但保留当前的有效 Token
        _user = User.fromJson({
          ...response.data['data'],
          'token': currentToken,
        });
        await _saveUserToPrefs();
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
        if (response.data['data'] != null && 
           (response.data['data']['token'] != null || response.data['data']['accessToken'] != null)) {
          _user = User.fromJson(response.data['data']);
          await _saveUserToPrefs();
        }
        return true;
      } else {
        throw Exception(response.data['message'] ?? '注册失败');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? '注册失败');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _refreshToken() async {
    try {
      // POST /auth/refresh，鉴权：否（通过 refreshToken Cookie）
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
    } catch (e) {
      debugPrint('Token 刷新异常: $e');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      if (_user != null) await _dio.post('/auth/logout');
    } catch (e) {
      debugPrint('登出请求异常 (正常流程继续): $e');
    } finally {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      _cookieJar.deleteAll(); // 清空 Cookie
      notifyListeners();
    }
  }

  // 彻底注销账号
  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _dio.delete('/auth/me');
      if (response.data['code'] == 200) {
        _user = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_data');
        _cookieJar.deleteAll();
        return true;
      }
    } on DioException catch (e) {
      debugPrint('注销账号失败: ${e.message}');
      rethrow;
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
}
