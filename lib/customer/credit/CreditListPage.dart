import 'package:ekoperasi/customer/akun/akuncustomer.dart';
import 'package:ekoperasi/customer/credit/CreditDetailPage.dart';
import 'package:ekoperasi/customer/homepage.dart';
import 'package:ekoperasi/customer/pesanan/riwayat.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreditListPage extends StatefulWidget {
  const CreditListPage({super.key});

  @override
  State<CreditListPage> createState() => _CreditListPageState();
}

class _CreditListPageState extends State<CreditListPage> {
  Future<List<dynamic>>? _creditFuture;
  int _selectedIndex = 2;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<dynamic>> fetchCredits(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.43.202:8000/api/credits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat data kredit');
      }
    } catch (e) {
      print('Error saat fetchCredits: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    print('InitState dipanggil');
    getToken().then((token) {
      if (token != null) {
        print('Memulai fetchCredits...');
        setState(() {
          _creditFuture = fetchCredits(token);
        });
      } else {
        print('Token null, user belum login?');
      }
    });
  }

  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'paid':
        return 'Lunas';
      case 'overdue':
        return 'Terlambat';
      default:
        return status;
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
            builder: (context) => HomePage(userName: 'NamaUser'),
          ),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RiwayatPage()),
          (route) => false,
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AccountPage()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kredit Saya",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF016A63),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _creditFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: _creditFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final credits = snapshot.data!;
                  if (credits.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada kredit.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: credits.length,
                    itemBuilder: (context, index) {
                      final credit = credits[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          title: Text(
                            "Total: Rp ${credit['total_credit']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Sisa: Rp ${credit['credit_remaining']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF016A63).withOpacity(0.1),
                              border: Border.all(
                                  color: const Color(0xFF016A63), width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              getStatusLabel(credit['status']),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF016A63)),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreditDetailPage(creditId: credit['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card), label: 'Credit'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}
