import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreditDetailPage1 extends StatefulWidget {
  final int creditId;
  final bool isLoading;

  const CreditDetailPage1(
      {super.key, required this.creditId, this.isLoading = false});

  @override
  State<CreditDetailPage1> createState() => _CreditDetailPage1State();
}

class _CreditDetailPage1State extends State<CreditDetailPage1> {
  Map<String, dynamic>? creditDetail;
  bool isLoading = true;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchCreditDetail() async {
    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
            'http://192.168.43.202:8000/api/credits/${widget.creditId}/detail'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          creditDetail = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat detail kredit');
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCreditDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kredit'),
        backgroundColor: const Color(0xFF016A63),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : creditDetail == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bagian Detail Kredit
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Detail Kredit",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildDetailRow("User", creditDetail!['user']),
                              _buildDetailRow("Total Kredit",
                                  "Rp ${creditDetail!['total_credit']}"),
                              _buildDetailRow("Sisa Kredit",
                                  "Rp ${creditDetail!['credit_remaining']}"),
                              _buildDetailRow(
                                  "Status", creditDetail!['status']),
                              _buildDetailRow(
                                  "Jatuh Tempo", creditDetail!['due_date']),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bagian Riwayat Pembayaran
                      Text("Riwayat Pembayaran",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      ...creditDetail!['payments'].map<Widget>((p) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.payment,
                                color: Color(0xFF016A63)),
                            title: Text(
                              "Rp ${p['jumlah']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tanggal: ${p['tanggal']}"),
                                Text("Catatan: ${p['catatan']}"),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
