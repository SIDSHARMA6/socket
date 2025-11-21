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
      print("=== SENDING OTP ===");
      print("Email: $email");
      print("URL: ${ApiService.baseUrl}/api/auth/send-otp");

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/send-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print("Response status: ${res.statusCode}");
      print("Response body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      print("Send OTP error: $e");
      return false;
    }
  }

  static Future<bool> verifyOtpAndReset(
      String email, String otp, String newPassword) async {
    try {
      print("=== VERIFYING OTP ===");
      print("Email: $email");
      print("OTP: $otp");

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/auth/verify-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      print("Response status: ${res.statusCode}");
      print("Response body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      print("Verify OTP error: $e");
      return false;
    }
  }
}
