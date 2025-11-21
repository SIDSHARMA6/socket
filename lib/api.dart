import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For local development: http://localhost:1337 (emulator) or http://YOUR_IP:1337 (device)
  // For production: https://your-app.onrender.com
  static String baseUrl = "https://socket-cxer.onrender.com";

  static Future<List> getMessages() async {
    try {
      print("=== GET MESSAGES (NO AUTH) ===");
      print("URL: $baseUrl/api/messages?populate=*");

      final res = await http.get(Uri.parse("$baseUrl/api/messages?populate=*"));

      print("Status: ${res.statusCode}");
      print("Response: ${res.body}");

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
      print("=== GET MESSAGES WITH AUTH ===");
      print("URL: $baseUrl/api/messages?populate=*");
      print("Token: ${token.substring(0, 20)}...");

      final res = await http.get(
        Uri.parse("$baseUrl/api/messages?populate=*"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Status: ${res.statusCode}");
      print("Response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("Decoded data type: ${data.runtimeType}");

        // Check if data is already a list or wrapped in "data" field
        if (data is List) {
          print("Data is List, length: ${data.length}");
          return data;
        } else if (data is Map && data.containsKey('data')) {
          print("Data is Map with 'data' field");
          return data['data'] ?? [];
        }
        print("Data format not recognized");
        return [];
      }
      print("Non-200 status code");
      return [];
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }
}
