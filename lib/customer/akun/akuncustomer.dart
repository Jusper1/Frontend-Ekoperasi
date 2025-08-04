// import 'package:ekoperasi/customer/akun/SettingsPage.dart';
import 'package:flutter/material.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:ekoperasi/login.dart';

// ignore: use_key_in_widget_constructors
class AccountPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();
  String? userName = "User";
  String? userEmail = "user@example.com";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.fetchUserData();
    if (userData != null) {
      setState(() {
        userName = userData['name'];
        userEmail = userData['email'];
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Tidak"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Iya"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _authService.logout();
      // Navigasi ke halaman login dan hapus semua halaman sebelumnya dari tumpukan
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Menghapus semua rute sebelumnya
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF016A63),
        title: const Text("Akun Saya",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
        // leading: IconButton(  // HAPUS BAGIAN INI
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, $userName", style: const TextStyle(fontSize: 20)),
            Text(
              userEmail ??
                  "Email tidak ditemukan", // Tampilkan email di bawah nama
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 30, thickness: 1),
            // ListTile(
            //   leading: const Icon(Icons.settings),
            //   title: const Text("Pengaturan"),
            //   subtitle: const Text("Ubah data akun Anda"),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => SettingsPage(
            //           name: userName ?? '',
            //           email: userEmail ?? '',
            //         ),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Logout"),
              subtitle: const Text("Keluar Dari Akun"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}
