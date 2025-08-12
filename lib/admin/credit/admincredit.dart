import 'dart:convert';
import 'package:ekoperasi/admin/credit/detailcredit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminCredit extends StatefulWidget {
  const AdminCredit({super.key});

  @override
  State<AdminCredit> createState() => _AdminCreditState();
}

class _AdminCreditState extends State<AdminCredit> {
  List credits = [];
  bool isLoading = true;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  void initState() {
    super.initState();
    fetchCredits();
  }

  Future<void> fetchCredits() async {
    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.43.202:8000/api/credits/active'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          credits = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat kredit');
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsPaid(int id) async {
    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.43.202:8000/api/credits/$id/mark-paid'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kredit berhasil ditandai lunas')),
        );
        fetchCredits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai kredit')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kredit Aktif'),
        backgroundColor: const Color(0xFF016A63),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: credits.length,
              itemBuilder: (context, index) {
                final credit = credits[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreditDetailPage1(creditId: credit['id']),
                        ),
                      );
                    },
                    title: Text(credit['user_name'] ?? 'Tanpa Nama'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: Rp ${credit['total_credit']}'),
                        Text('Sisa: Rp ${credit['remaining_credit']}'),
                        Text('Status: ${credit['status']}'),
                      ],
                    ),
                    trailing: credit['status'] != 'paid'
                        ? IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              markAsPaid(credit['id']);
                            },
                          )
                        : const Icon(Icons.done, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
