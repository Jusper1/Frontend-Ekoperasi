import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreditDetailPage extends StatefulWidget {
  final int creditId;

  const CreditDetailPage({super.key, required this.creditId});

  @override
  State<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends State<CreditDetailPage> {
  Map<String, dynamic>? credit;
  List<dynamic> payments = [];

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchDetail() async {
    final token = await getToken();
    if (token == null) return;

    final creditRes = await http.get(
      Uri.parse('http://192.168.43.202:8000/api/credits'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final paymentsRes = await http.get(
      Uri.parse(
          'http://192.168.43.202:8000/api/credits/${widget.creditId}/payments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (creditRes.statusCode == 200 && paymentsRes.statusCode == 200) {
      final creditList = json.decode(creditRes.body);
      final detail = creditList.firstWhere((e) => e['id'] == widget.creditId);
      final paymentList = json.decode(paymentsRes.body);

      setState(() {
        credit = detail;
        payments = paymentList;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (credit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Kredit")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Kredit : Rp ${credit!['total_credit']}"),
            Text("Sisa Kredit  : Rp ${credit!['credit_remaining']}"),
            Text("Status       : ${credit!['status']}"),
            const SizedBox(height: 20),
            const Text("Riwayat Pembayaran:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: payments.isEmpty
                  ? const Text("Belum ada pembayaran.")
                  : ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final p = payments[index];
                        return ListTile(
                          title: Text("Rp ${p['amount']}"),
                          subtitle: Text(p['paid_at']),
                          trailing: Text(p['note'] ?? '-'),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              "* Pembayaran kredit dilakukan langsung kepada admin.",
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
