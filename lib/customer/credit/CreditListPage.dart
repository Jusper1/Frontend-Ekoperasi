import 'package:ekoperasi/customer/credit/CreditDetailPage.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kredit Saya')),
      body: _creditFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: _creditFuture,
              builder: (context, snapshot) {
                print('FutureBuilder status: ${snapshot.connectionState}');
                if (snapshot.hasData) {
                  final credits = snapshot.data!;
                  print('Jumlah kredit ditemukan: ${credits.length}');
                  if (credits.isEmpty) {
                    return const Center(child: Text('Tidak ada kredit.'));
                  }

                  return ListView.builder(
                    itemCount: credits.length,
                    itemBuilder: (context, index) {
                      final credit = credits[index];
                      return ListTile(
                        title: Text("Total: Rp ${credit['total_credit']}"),
                        subtitle:
                            Text("Sisa: Rp ${credit['credit_remaining']}"),
                        trailing: Text(credit['status']),
                        onTap: () {
                          print('Klik kredit ID: ${credit['id']}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreditDetailPage(creditId: credit['id']),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  print('Terjadi error di FutureBuilder: ${snapshot.error}');
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}
