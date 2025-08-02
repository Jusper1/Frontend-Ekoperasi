// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ekoperasi/customer/pesanan/riwayat.dart';
import 'dart:convert';
import 'package:ekoperasi/customer/produk/keranjang.dart';
import 'package:ekoperasi/service/api_service.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PembayaranPage extends StatefulWidget {
  final List<CartItem>
      cartItems; // Menggunakan CartItem untuk mendapatkan ID produk
  final double totalPrice;

  // ignore: use_super_parameters
  const PembayaranPage({
    Key? key,
    required this.cartItems, // Menggunakan CartItem
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  final formatter = NumberFormat('#,###', 'id_ID');
  String selectedPaymentMethod = 'Bank Transfer';
  String selectedDeliveryMethod = 'Diantar';
  TextEditingController addressController = TextEditingController();

  void processPayment() async {
    // ignore: unused_local_variable
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        await AuthService().getToken(); // Ambil token dari AuthService

    // Ambil data user
    final userResponse = await ApiService().getUserProfile();
    String userId = '';

    if (userResponse.statusCode == 200) {
      final userData = json.decode(userResponse.body);
      userId = userData['id'].toString(); // Sesuaikan dengan struktur respons
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data pengguna")));
      return;
    }

    // Pertama, kita buat order
    final url = Uri.parse('http://192.168.43.202:8000/api/orders');

    print('Membuat order...');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sertakan token dalam header
      },
      body: json.encode({
        'user_id': userId, // Gunakan user_id yang didapat dari API
        'payment_method': selectedPaymentMethod,
        'delivery_method': selectedDeliveryMethod,
        'address':
            selectedDeliveryMethod == 'Diantar' ? addressController.text : '',
        'total_price': widget.totalPrice.toString(),
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final orderData = json.decode(response.body);
      final orderId = orderData['id'];

      // Kemudian, kita simpan item pesanan
      for (int i = 0; i < widget.cartItems.length; i++) {
        final item = widget.cartItems[i];
        print('Mengirim item pesanan:');
        print('Order ID: $orderId');
        print('Product ID: ${item.id}'); // Menggunakan ID produk dari CartItem
        print('Quantity: ${item.quantity}');

        final orderItemUrl =
            Uri.parse('http://192.168.43.202:8000/api/order-items');
        final orderItemResponse = await http.post(orderItemUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // Sertakan token dalam header
            },
            body: json.encode({
              'order_id': orderId.toString(),
              'product_id':
                  item.id.toString(), // Menggunakan ID produk dari CartItem
              'quantity': item.quantity.toString(),
              'price': (widget.totalPrice / widget.cartItems.length).toString(),
            }));

        print('Order Item Response status: ${orderItemResponse.statusCode}');
        print('Order Item Response body: ${orderItemResponse.body}');

        if (orderItemResponse.statusCode != 201) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal menyimpan item pesanan")));
          return;
        }
      }

      // Jika semua item pesanan berhasil disimpan, tampilkan snackbar dan navigasi ke CartPage
      _showSuccessSnackbar();
    } else {
      // Gagal membuat order
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal membuat order")));
    }
  }

  void _showSuccessSnackbar() {
    // ignore: prefer_const_declarations
    final snackBar = const SnackBar(
      content: Text('Pesanan Anda sedang diproses!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Navigasi ke CartPage setelah snackbar ditampilkan
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatPage()),
      );
    });
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembayaran'),
          content:
              const Text('Apakah Anda yakin ingin melanjutkan pembayaran?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
                processPayment(); // Memproses pembayaran
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF67C4A7),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pesanan:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatter.format(widget.totalPrice)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              title: const Text('Bank Transfer'),
              value: 'Bank Transfer',
              groupValue: selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => selectedPaymentMethod = value.toString()),
            ),
            RadioListTile(
              title: const Text('Cash'),
              value: 'Cash',
              groupValue: selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => selectedPaymentMethod = value.toString()),
            ),
            const SizedBox(height: 20),
            if (selectedPaymentMethod == 'Bank Transfer')
              const Text(
                'Nomor Rekening: 123-456-7890 (Basmida Laia)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const SizedBox(height: 20),
            const Text('Pilih Metode Pengiriman',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RadioListTile(
              title: const Text('Diantar'),
              value: 'Diantar',
              groupValue: selectedDeliveryMethod,
              onChanged: (value) =>
                  setState(() => selectedDeliveryMethod = value.toString()),
            ),
            RadioListTile(
              title: const Text('Jemput Sendiri'),
              value: 'Jemput Sendiri',
              groupValue: selectedDeliveryMethod,
              onChanged: (value) =>
                  setState(() => selectedDeliveryMethod = value.toString()),
            ),
            if (selectedDeliveryMethod == 'Diantar')
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan alamat lengkap Anda',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _showConfirmationDialog, // Menampilkan dialog konfirmasi
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67C4A7),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
