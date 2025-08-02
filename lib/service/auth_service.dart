// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String apiUrl = "http://192.168.43.202:8000/api/login";

  get fetchUser => null;

  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse("http://192.168.43.202:8000/api/user"),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          print("Failed to fetch user data: ${response.body}");
        }
      } else {
        print("No token found");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://192.168.43.202:8000/api/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'user_id', responseData['id']); // Menyimpan ID pengguna
      await prefs.setString(
          'user_name', responseData['name']); // Menyimpan nama pengguna
      await prefs.setString(
          'user_email', responseData['email']); // Menyimpan email pengguna

      // Navigasi ke halaman utama atau dashboard
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      await http.post(
        Uri.parse("http://192.168.43.202:8000/api/logout"),
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    await prefs.remove('access_token');
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
