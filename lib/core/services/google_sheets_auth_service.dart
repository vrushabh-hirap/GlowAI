import 'dart:convert';
import 'package:dio/dio.dart';

class GoogleSheetsAuthService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbwemCVYIehUqS4-S5U1ESQ6WFZVjDR2XQxthWIE9vgR20bkeTkusvJVLNKJsl7vXAat9Q/exec';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// Returns {ok: true, user: {...}} or {ok: false, message: "..."}
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String age,
    required String gender,
  }) async {
    return _post({
      'action': 'signup',
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'age': age,
      'gender': gender,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String newPassword,
  }) async {
    return _post({
      'action': 'resetPassword',
      'email': email,
      'password': password,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> updateDoctorProfile({
    required String id,
    String? name,
    String? phone,
    String? specialty,
    String? experience,
    String? languages,
    String? fee,
    String? bio,
    String? photoUrl,
    String? clinicAddress,
    String? modes,
    String? isAvailable,
  }) async {
    return _post({
      'action': 'updateDoctorProfile',
      'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (specialty != null) 'specialty': specialty,
      if (experience != null) 'experience': experience,
      if (languages != null) 'languages': languages,
      if (fee != null) 'fee': fee,
      if (bio != null) 'bio': bio,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (clinicAddress != null) 'clinicAddress': clinicAddress,
      if (modes != null) 'modes': modes,
      if (isAvailable != null) 'isAvailable': isAvailable,
    });
  }

  Future<Map<String, dynamic>> listDoctors() async {
    return _post({'action': 'listDoctors'});
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String role,
    required String newPassword,
  }) async {
    return _post({
      'action': 'forgotPassword',
      'email': email,
      'role': role,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return _post({
      'action': 'login',
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: body,
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is String) {
        try {
          return Map<String, dynamic>.from(jsonDecode(data) as Map);
        } catch (_) {
          return {'ok': false, 'message': 'Unexpected server response'};
        }
      }
      return {'ok': false, 'message': 'Unexpected server response'};
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        // one automatic retry for transient network timeouts
        try {
          final response2 = await _dio.get(_baseUrl, queryParameters: body);
          final data2 = response2.data;
          if (data2 is Map) {
            return Map<String, dynamic>.from(data2);
          }
          if (data2 is String) {
            try {
              return Map<String, dynamic>.from(jsonDecode(data2) as Map);
            } catch (_) {
              return {'ok': false, 'message': 'Unexpected server response'};
            }
          }
        } catch (_) {}
      }
      return {'ok': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'ok': false, 'message': 'Error: $e'};
    }
  }
}
