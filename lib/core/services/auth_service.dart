import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../mock/mock_data.dart';

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

  AuthNotifier(this._service) : super(_service.currentUser);

  void login(String email, String password, UserRole role) {
    _service.login(email, password, role);
    state = _service.currentUser;
  }

  void switchRole(UserRole newRole) {
    _service.switchRole(newRole);
    state = _service.currentUser;
  }

  void togglePremium() {
    state = state.copyWith(isPremium: !state.isPremium);
  }

  void logout() {
    _service.logout();
    state = MockData.patientUser;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => FakeAuthService());

final authProvider = StateNotifierProvider<AuthNotifier, UserModel>((ref) {
  final service = ref.watch(authServiceProvider) as FakeAuthService;
  return AuthNotifier(service);
});
