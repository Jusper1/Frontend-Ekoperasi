import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryCreditPage extends StatefulWidget {
  final int creditId;
  const HistoryCreditPage({Key? key, required this.creditId}) : super(key: key);

  @override
  State<HistoryCreditPage> createState() => _HistoryCreditPageState();
}

class _HistoryCreditPageState extends State<HistoryCreditPage> {
  bool isLoading = true;
  List<dynamic> paymentHistory = [];

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  @override
  void initState() {
    super.initState();
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
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
        final data = json.decode(response.body);
        setState(() {
          paymentHistory = data['payments'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String formatCurrency(dynamic value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    return formatter.format(value ?? 0);
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy HH:mm').format(parsedDate);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        backgroundColor: const Color(0xFF016A63),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentHistory.isEmpty
              ? const Center(child: Text('Belum ada riwayat pembayaran'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = paymentHistory[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: Colors.teal),
                        title: Text(
                          formatCurrency(payment['jumlah']),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal: ${formatDate(payment['tanggal'])}'),
                            Text('Catatan: ${payment['catatan'] ?? '-'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
