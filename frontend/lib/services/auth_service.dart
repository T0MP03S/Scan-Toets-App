import 'package:toets_scan_app/models/user_model.dart';
import 'package:toets_scan_app/services/api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    _api.setToken(response['access_token']);
    return response;
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    return UserModel.fromJson(response);
  }

  Future<UserModel> getMe() async {
    final response = await _api.get('/auth/me');
    return UserModel.fromJson(response);
  }

  void logout() {
    _api.setToken(null);
  }
}
