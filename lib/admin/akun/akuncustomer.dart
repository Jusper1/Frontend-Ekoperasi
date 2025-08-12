import 'package:ekoperasi/admin/homepage2.dart';
import 'package:ekoperasi/admin/pesanan/listpesanan.dart';
import 'package:ekoperasi/admin/pesanan/riwayatpesanan.dart';
import 'package:flutter/material.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:ekoperasi/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: use_key_in_widget_constructors
class AccountPage1 extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _AccountPage1State createState() => _AccountPage1State();
}

class _AccountPage1State extends State<AccountPage1> {
  final AuthService _authService = AuthService();
  String? userName = "User";
  String? userEmail = "user@example.com";
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.fetchUserData();
    if (userData != null) {
      SharedPreferences prefs =
          await SharedPreferences.getInstance(); // tambahkan ini

      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_no_hp', userData['no_hp'] ?? '');
      await prefs.setString('user_alamat', userData['alamat'] ?? '');

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage2(userName: 'NamaUser'),
          ),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ListPesananPage()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RiwayatPage()),
          (route) => false,
        );
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Akun Saya",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF016A63),
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
            //   onTap: () async {
            //     final prefs = await SharedPreferences.getInstance();
            //     final result = await Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => SettingsPage(
            //           name: prefs.getString('user_name') ?? '',
            //           email: prefs.getString('user_email') ?? '',
            //           noHp: prefs.getString('user_no_hp') ?? '',
            //           alamat: prefs.getString('user_alamat') ?? '',
            //         ),
            //       ),
            //     );

            //     // Jika result == true, refresh ulang data profil
            //     if (result == true) {
            //       _loadUserData();
            //     }
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_checkout_outlined),
              label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}
