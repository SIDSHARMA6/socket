import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class AuthService {
  static Future<Map<String, dynamic>?> signup(
      String username, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/local/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("Signup error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login(
      String identifier, String password) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/local"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  static Future<bool> sendOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/send-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Send OTP error: $e");
      return false;
    }
  }

  static Future<bool> verifyOtpAndReset(
      String email, String otp, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/verify-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("Verify OTP error: $e");
      return false;
    }
  }
}
