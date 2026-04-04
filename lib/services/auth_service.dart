import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/app_constants.dart';

class AuthService extends ChangeNotifier {
  static const String _userPrefsKey = 'user_data';
  static const String _refreshTokenPrefsKey = 'refresh_token';

  User? _user;
  bool _isLoading = false;
  late final Dio _dio;
  late final CookieJar _cookieJar;
  Future<bool>? _refreshFuture;

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
        if (_user != null && _user!.token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${_user!.token}';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (_shouldTryRefresh(e)) {
          final refreshed = await _refreshToken();
          if (refreshed && _user != null) {
            final retryOptions = e.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer ${_user!.token}';
            retryOptions.extra['skipAuthRefresh'] = true;
            final retryResponse = await _dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }
          await logout();
        }
        handler.next(e);
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
          refreshToken: _user!.refreshToken,
        );
        await _saveUserToPrefs();
        notifyListeners();
        return true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userPrefsKey);
    final savedRefreshToken = prefs.getString(_refreshTokenPrefsKey) ?? '';
    if (userJson == null) return;

    try {
      final loaded = User.fromJson(jsonDecode(userJson));
      _user = User(
        id: loaded.id,
        username: loaded.username,
        nickname: loaded.nickname,
        token: loaded.token,
        refreshToken:
            loaded.refreshToken.isNotEmpty ? loaded.refreshToken : savedRefreshToken,
      );
      notifyListeners();
    } catch (_) {
      await prefs.remove(_userPrefsKey);
      await prefs.remove(_refreshTokenPrefsKey);
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
        final baseUser = User.fromJson(
          Map<String, dynamic>.from(response.data['data'] ?? const {}),
        );
        final refreshToken = _extractRefreshTokenFromResponse(response) ?? '';
        _user = User(
          id: baseUser.id,
          username: baseUser.username,
          nickname: baseUser.nickname,
          token: baseUser.token,
          refreshToken: refreshToken,
        );
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
          final baseUser = User.fromJson(
            Map<String, dynamic>.from(response.data['data'] ?? const {}),
          );
          final refreshToken = _extractRefreshTokenFromResponse(response) ?? '';
          _user = User(
            id: baseUser.id,
            username: baseUser.username,
            nickname: baseUser.nickname,
            token: baseUser.token,
            refreshToken: refreshToken,
          );
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
      if (_user != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(
            headers: _buildRefreshTokenCookieHeader(_user!.refreshToken),
            extra: {'skipAuthRefresh': true},
          ),
        );
      }
    } catch (_) {
    } finally {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefsKey);
      await prefs.remove(_refreshTokenPrefsKey);
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
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPrefsKey, jsonEncode(_user!.toJson()));
    await prefs.setString(_refreshTokenPrefsKey, _user!.refreshToken);
  }

  Future<bool> _refreshToken() async {
    if (_refreshFuture != null) return _refreshFuture!;
    _refreshFuture = _performRefreshToken();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  Future<bool> _performRefreshToken() async {
    if (_user == null || _user!.refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: _buildRefreshTokenCookieHeader(_user!.refreshToken),
          extra: {'skipAuthRefresh': true},
        ),
      );

      if (response.data['code'] == 200) {
        final data = response.data['data'] ?? const {};
        final newAccessToken = data['token'] ?? data['accessToken'];
        if (newAccessToken is! String || newAccessToken.isEmpty) return false;

        final rotatedRefreshToken =
            _extractRefreshTokenFromResponse(response) ?? _user!.refreshToken;

        _user = User(
          id: _user!.id,
          username: _user!.username,
          nickname: _user!.nickname,
          token: newAccessToken,
          refreshToken: rotatedRefreshToken,
        );
        await _saveUserToPrefs();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool _shouldTryRefresh(DioException e) {
    if (e.response?.statusCode != 401 || _user == null) return false;
    if (e.requestOptions.extra['skipAuthRefresh'] == true) return false;

    final path = e.requestOptions.path;
    return path != '/auth/login' &&
        path != '/auth/register' &&
        path != '/auth/refresh' &&
        path != '/auth/logout';
  }

  Map<String, dynamic> _buildRefreshTokenCookieHeader(String refreshToken) {
    if (refreshToken.isEmpty) return {};
    return {'Cookie': 'refreshToken=${Uri.encodeComponent(refreshToken)}'};
  }

  String? _extractRefreshTokenFromResponse(Response response) {
    final setCookieHeaders = response.headers.map['set-cookie'];
    if (setCookieHeaders == null) return null;

    for (final header in setCookieHeaders) {
      for (final part in header.split(';')) {
        final trimmed = part.trim();
        if (trimmed.startsWith('refreshToken=')) {
          return Uri.decodeComponent(trimmed.substring('refreshToken='.length));
        }
      }
    }
    return null;
  }
}
