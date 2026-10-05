import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../mock/mock_data.dart';
import 'google_sheets_auth_service.dart';

// TODO(module: auth) replace with real Hive + SHA-256 local auth service

abstract class AuthService {
  UserModel get currentUser;
  bool get isLoggedIn;
  void login(String email, String password, UserRole role);
  void switchRole(UserRole newRole);
  void logout();
}

class FakeAuthService implements AuthService {
  UserModel _user = MockData.patientUser;
  bool _isLoggedIn = true;

  @override
  UserModel get currentUser => _user;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  void login(String email, String password, UserRole role) {
    _isLoggedIn = true;
    if (role == UserRole.doctor) {
      _user = MockData.doctorUser;
    } else {
      _user = MockData.patientUser.copyWith(email: email);
    }
  }

  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_name', user.name);
    await prefs.setString('session_email', user.email);
    await prefs.setString('session_role', user.role == UserRole.doctor ? 'doctor' : 'patient');
    await prefs.setInt('session_age', user.age);
    await prefs.setString('session_gender', user.gender);
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('session_email');
    final roleStr = prefs.getString('session_role');
    if (email == null || roleStr == null) return;
    _isLoggedIn = true;
    final role = roleStr == 'doctor' ? UserRole.doctor : UserRole.patient;
    _user = UserModel(
      id: 'session',
      name: prefs.getString('session_name') ?? '',
      email: email,
      role: role,
      age: prefs.getInt('session_age') ?? 26,
      gender: prefs.getString('session_gender') ?? 'Female',
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_name');
    await prefs.remove('session_email');
    await prefs.remove('session_role');
    await prefs.remove('session_age');
    await prefs.remove('session_gender');
  }

  @override
  void switchRole(UserRole newRole) {
    if (newRole == UserRole.doctor) {
      _user = MockData.doctorUser;
    } else {
      _user = MockData.patientUser;
    }
  }

  @override
  void logout() {
    _isLoggedIn = false;
  }
}

class AuthNotifier extends StateNotifier<UserModel> {
  final FakeAuthService _service;
  final GoogleSheetsAuthService _sheets = GoogleSheetsAuthService();

  AuthNotifier(this._service) : super(_service.currentUser) {
    _restore();
  }

  Future<void> _restore() async {
    await _service.restoreSession();
    state = _service.currentUser;
  }

  Future<Map<String, dynamic>> login(String email, String password, UserRole role) async {
    final res = await _sheets.login(
      email: email,
      password: password,
      role: role == UserRole.doctor ? 'doctor' : 'patient',
    );
    if (res['ok'] == true) {
      final u = res['user'] as Map;
      _service.login(email, password, role);
      state = UserModel(
        id: u['id']?.toString() ?? 'u_0',
        name: u['name']?.toString() ?? '',
        email: u['email']?.toString() ?? email,
        role: role,
        age: int.tryParse(u['age']?.toString() ?? '') ?? 26,
        gender: u['gender']?.toString() ?? 'Female',
      );
      await _service.saveSession(state);
    }
    return res;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
    required String age,
    required String gender,
  }) async {
    final res = await _sheets.signup(
      name: name,
      email: email,
      password: password,
      role: role == UserRole.doctor ? 'doctor' : 'patient',
      phone: phone,
      age: age,
      gender: gender,
    );
    if (res['ok'] == true) {
      final u = res['user'] as Map;
      _service.login(email, password, role);
      state = UserModel(
        id: u['id']?.toString() ?? 'u_0',
        name: u['name']?.toString() ?? name,
        email: u['email']?.toString() ?? email,
        role: role,
        age: int.tryParse(u['age']?.toString() ?? '') ?? 26,
        gender: u['gender']?.toString() ?? gender,
      );
      await _service.saveSession(state);
    }
    return res;
  }

  void switchRole(UserRole newRole) {
    _service.switchRole(newRole);
    state = _service.currentUser;
  }

  void togglePremium() {
    state = state.copyWith(isPremium: !state.isPremium);
  }

  void updateName(String newName) {
    state = state.copyWith(name: newName);
  }

  void logout() {
    _service.logout();
    _service.clearSession();
    state = MockData.patientUser;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => FakeAuthService());

final authProvider = StateNotifierProvider<AuthNotifier, UserModel>((ref) {
  final service = ref.watch(authServiceProvider) as FakeAuthService;
  return AuthNotifier(service);
});
