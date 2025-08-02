import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Fungsi untuk mendapatkan profil pengguna
  Future<http.Response> getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://192.168.43.202:8000/api/user'),
      headers: {
        'Authorization': 'Bearer $token', // Menyertakan token dalam header
      },
    );

    return response;
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await http
        .get(Uri.parse('http://192.168.43.202:8000/api/homepage/stats'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data');
    }
  }
}
