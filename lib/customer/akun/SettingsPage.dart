import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  final String name;
  final String email;

  const SettingsPage({Key? key, required this.name, required this.email})
      : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _nameController.text = widget.name;
    _emailController.text = widget.email;

    final prefs = await SharedPreferences.getInstance();
    _noHpController.text = prefs.getString('user_no_hp') ?? '';
    _alamatController.text = prefs.getString('user_alamat') ?? '';
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('http://192.168.43.202:8000/api/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirmation': _passwordController.text,
        'no_hp': _noHpController.text,
        'alamat': _alamatController.text,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_email', _emailController.text);
      await prefs.setString('user_no_hp', _noHpController.text);
      await prefs.setString('user_alamat', _alamatController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui profil")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        ),
        backgroundColor: const Color(0xFF67C4A7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pribadi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noHpController,
              decoration: const InputDecoration(
                labelText: "No HP",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _alamatController,
              decoration: const InputDecoration(
                labelText: "Alamat",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ganti Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(),
                suffixText: 'Opsional',
                suffixStyle: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67C4A7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "Simpan Perubahan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
