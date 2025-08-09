// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ekoperasi/admin/keuangan/manajemenkeuangan.dart';
import 'package:ekoperasi/admin/pengguna/listpengguna.dart';
import 'package:ekoperasi/admin/pesanan/riwayatpesanan.dart';
import 'package:ekoperasi/admin/produk/listproduct.dart';
import 'package:ekoperasi/admin/stokbahan/liststokbahan.dart';
import 'package:ekoperasi/admin/pesanan/listpesanan.dart';
import 'package:ekoperasi/customer/akun/akuncustomer.dart';
import 'package:ekoperasi/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HomePage2 extends StatefulWidget {
  final String userName;

  // ignore: use_super_parameters
  const HomePage2({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  TextEditingController searchController = TextEditingController();
  int _selectedIndex = 0;
  int _notificationCount = 0; // Menyimpan jumlah notifikasi
  Timer? _timer; // Timer untuk auto-refresh
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    fetchNotificationCount(); // Ambil jumlah notifikasi saat inisialisasi
    _statsFuture = ApiService().fetchDashboardStats();

    // Inisialisasi timer untuk auto-refresh
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchNotificationCount(); // Panggil fetchNotificationCount setiap 10 detik
    });
  }

  Future<void> fetchNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    final url = Uri.parse('http://192.168.43.202:8000/api/notifications/count');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _notificationCount = data['count']; // Set jumlah notifikasi
      });
    } else {
      print('Failed to load notification count: ${response.statusCode}');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ListPesananPage()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const RiwayatPage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AccountPage()));
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan timer
    super.dispose();
  }

  // ignore: unused_element
  Widget _buildCategoryIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Menambahkan aksi saat ditekan
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(
                12.0), // Mengubah padding untuk tampilan lebih baik
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void refreshNotificationCount() {
    fetchNotificationCount(); // Panggil fetchNotificationCount
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF67C4A7),
        title: const Text("E-Koperasi",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(
          //     Icons.shopping_cart,
          //     color: Colors.black,
          //   ),
          // ),
          IconButton(
            onPressed: () {
              // Navigasi ke halaman notifikasi
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ListPesananPage()),
              );
            },
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.black,
                  size: 30,
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 40,
                child: TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Cari di sini',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade100),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF67C4A7).withOpacity(0.8),
                      const Color(0xFF8BC34A).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  // Menggunakan Row untuk menempatkan ilustrasi dan teks
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Menggunakan Expanded untuk menempatkan teks dan tombol di sisi kiri
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              'Jln. bukittinggi',
                              style: TextStyle(
                                fontSize: 14, // Adjusted font size
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Text(
                              'Nomor WhatsApp yang di gunakan sekarang :',
                              style: TextStyle(
                                fontSize: 10, // Adjusted font size
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const SizedBox(
                              height:
                                  4), // Spacing between the address and the button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: ElevatedButton(
                              onPressed: () {
                                // Open WhatsApp
                                String url =
                                    "https://wa.me/6285263154625"; // Replace with your WhatsApp number
                                // ignore: deprecated_member_use
                                launch(url);
                              },
                              // ignore: sort_child_properties_last
                              child: const Text(
                                '+6285263154625',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A7C5B)
                                    .withOpacity(0.5), // Green color
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menambahkan ilustrasi di sebelah kanan
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 16), // Spasi antara teks dan gambar
                      child: Image.asset(
                        './lib/assets/ilustrasi.png',
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryCard(Icons.store, 'Produk', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListProduct(),
                      ),
                    );
                  }),
                  _buildCategoryCard(Icons.inventory, 'Bahan Baku', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ListStokBahan()),
                    );
                  }),
                  _buildCategoryCard(Icons.person_search, 'Pengguna', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ListPengguna()),
                    );
                  }),
                  _buildCategoryCard(Icons.account_balance_wallet, 'Keuangan',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManajemenKeuangan()),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Terjadi kesalahan'));
                  } else if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistik',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCard(
                              'Pesanan',
                              stats['pendingOrders'].toString(),
                              Icons.pending_actions,
                              const Color(
                                  0xFFFFA726), // Warna oranye yang lebih terang
                            ),
                            _buildStatCard(
                              'Produk',
                              stats['totalProduk'].toString(),
                              Icons.shopping_bag,
                              const Color(0xFF42A5F5), // Biru muda
                            ),
                            _buildStatCard(
                              'Customer',
                              stats['totalCustomer'].toString(),
                              Icons.people,
                              const Color(0xFF66BB6A), // Hijau
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text('Data tidak tersedia'));
                  }
                },
              ),
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

Widget _buildStatCard(String title, String count, IconData icon, Color color) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

// Fungsi untuk membuat kategori dengan ikon bulat
Widget _buildCategoryCard(IconData icon, String title, Function onTap) {
  return GestureDetector(
    onTap: () => onTap(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16), // Padding lebih besar untuk ikon
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2), // Soft color untuk ikon
            shape: BoxShape.circle, // Bentuk lingkaran
          ),
          child: Icon(icon,
              size: 32, color: Colors.black), // Ukuran ikon lebih besar
        ),
        const SizedBox(height: 12), // Spasi antara ikon dan teks
        Text(
          title,
          style: const TextStyle(
            fontSize: 14, // Ukuran teks lebih kecil
            fontWeight: FontWeight.w500,
            color: Colors.black87, // Warna teks lebih lembut
          ),
        ),
      ],
    ),
  );
}
