// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'crud_manajemenkeuangan.dart'; // Pastikan file UnexpectedExpenseScreen diimpor
import 'package:url_launcher/url_launcher.dart';

// ignore: use_key_in_widget_constructors
class ManajemenKeuangan extends StatefulWidget {
  @override
  _ManajemenKeuanganState createState() => _ManajemenKeuanganState();
}

class _ManajemenKeuanganState extends State<ManajemenKeuangan> {
  String _filter = "daily";
  double _totalIncome = 0;
  double _totalExpense = 0;

  List<Map<String, dynamic>> incomeData = [];
  List<Map<String, dynamic>> expenseData = [];

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  // Function to open PDF in browser
  Future<void> openPDFInBrowser() async {
    const url = 'http://192.168.43.202:8000/financial/pdf';
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _fetchFinancialData() async {
    try {
      String baseUrl = 'http://192.168.43.202:8000/api';
      final incomeResponse =
          await http.get(Uri.parse('$baseUrl/income?filter=$_filter'));
      final expenseResponse =
          await http.get(Uri.parse('$baseUrl/expenses?filter=$_filter'));
      final unexpectedExpenseResponse = await http
          .get(Uri.parse('$baseUrl/unexpected-expenses?filter=$_filter'));

      if (incomeResponse.statusCode == 200 &&
          expenseResponse.statusCode == 200 &&
          unexpectedExpenseResponse.statusCode == 200) {
        final incomeJson = json.decode(incomeResponse.body);
        final expenseJson = json.decode(expenseResponse.body);
        final unexpectedExpenseJson =
            json.decode(unexpectedExpenseResponse.body);

        setState(() {
          incomeData =
              List<Map<String, dynamic>>.from(incomeJson['data'] ?? []);
          List<Map<String, dynamic>> normalExpenses =
              List<Map<String, dynamic>>.from(expenseJson['data'] ?? []);
          List<Map<String, dynamic>> unexpectedExpenses =
              List<Map<String, dynamic>>.from(
                  unexpectedExpenseJson['data'] ?? []);

          // Gabungkan kedua jenis pengeluaran
          expenseData = [...normalExpenses, ...unexpectedExpenses];

          // Hitung total pemasukan dan pengeluaran
          _totalIncome = incomeData.fold(0.0, (sum, item) {
            return sum + (double.tryParse(item['amount'].toString()) ?? 0.0);
          });

          _totalExpense = expenseData.fold(0.0, (sum, item) {
            return sum + (double.tryParse(item['amount'].toString()) ?? 0.0);
          });
        });
      } else {
        throw Exception('Gagal mengambil data dari server');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String _getFilterLabel() {
    switch (_filter) {
      case "daily":
        return "Hari ini";
      case "weekly":
        return "Minggu ini";
      case "monthly":
        return "Bulan ini";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manajemen Keuangan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: openPDFInBrowser,
            tooltip: 'Unduh PDF',
          ),
        ],
        backgroundColor: const Color(0xFF016A63),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _filter,
              items: const [
                DropdownMenuItem(
                  value: "daily",
                  child: Text(
                    "Harian",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
                DropdownMenuItem(
                  value: "weekly",
                  child: Text(
                    "Mingguan",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
                DropdownMenuItem(
                  value: "monthly",
                  child: Text(
                    "Bulanan",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filter = value!;
                });
                _fetchFinancialData();
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.arrow_downward,
                            color: Colors.green, size: 30),
                        const SizedBox(height: 5),
                        const Text("Pemasukan"),
                        Text("Rp ${_totalIncome.toStringAsFixed(0)}"),
                        Text("(${_getFilterLabel()})",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.arrow_upward,
                            color: Colors.red, size: 30),
                        const SizedBox(height: 5),
                        const Text("Pengeluaran"),
                        Text("Rp ${_totalExpense.toStringAsFixed(0)}"),
                        Text("(${_getFilterLabel()})",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.blue, size: 30),
                        const SizedBox(height: 5),
                        const Text("Saldo"),
                        Text(
                            "Rp ${(_totalIncome - _totalExpense).toStringAsFixed(0)}"),
                        Text("(${_getFilterLabel()})",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDataCard("Pemasukan", incomeData),
            const SizedBox(height: 20),
            _buildDataCard("Pengeluaran", expenseData),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UnexpectedExpenseScreen()),
          );
        },
        backgroundColor: const Color(0xFF016A63),
        // ignore: sort_child_properties_last
        child: const Icon(Icons.add),
        tooltip: "Tambah Biaya Tidak Terduga",
      ),
    );
  }

  Widget _buildDataCard(String title, List<Map<String, dynamic>> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(
                    item['description'],
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold), // Memperkecil ukuran font
                  ),
                  subtitle: Text(
                    DateFormat('dd mmmm yyyy').format(DateTime.parse(
                        item['date'])), // Mengubah format tanggal
                  ),
                  trailing: Text(
                    "Rp ${item['amount']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
