import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For local development: http://localhost:1337 (emulator) or http://YOUR_IP:1337 (device)
  // For production: https://your-app.onrender.com
  static String baseUrl = "https://socket-cxer.onrender.com";

  static Future<List> getMessages() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/messages?populate=*"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["data"] ?? [];
      }
      return [];
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  static Future<List> getMessagesWithAuth(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/messages?populate=*"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data ?? [];
      }
      return [];
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }
}
