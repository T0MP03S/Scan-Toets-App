import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toets_scan_app/models/user_model.dart';
import 'package:toets_scan_app/services/api_service.dart';
import 'package:toets_scan_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  late final AuthService _authService;

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  AuthProvider(this._apiService) {
    _authService = AuthService(_apiService);
    _loadToken();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null) {
        _apiService.setToken(_token);
        try {
          _user = await _authService.getMe();
        } catch (_) {
          await _clearToken();
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _user = null;
    _apiService.setToken(null);
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      await _saveToken(response['access_token']);
      _user = await _authService.getMe();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(email, password, fullName);
      return await login(email, password);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _authService.logout();
    await _clearToken();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
