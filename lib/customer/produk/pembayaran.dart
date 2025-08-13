// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:ekoperasi/SelectLocationPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ekoperasi/customer/pesanan/riwayat.dart';
import 'dart:convert';
import 'package:ekoperasi/customer/produk/keranjang.dart';
import 'package:ekoperasi/service/api_service.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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
  String selectedPaymentMethod = 'Credit';
  String selectedDeliveryMethod = 'Diantar';

  TextEditingController addressController = TextEditingController();
  double? latitude;
  double? longitude;
  double ongkir = 0;
  double calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius Bumi dalam km
    final dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final dLon = (lon2 - lon1) * (3.141592653589793 / 180);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Jarak dalam km
  }

  @override
  void initState() {
    super.initState();
    addressController.text = ''; // Inisialisasi alamat kosong
  }

  void processPayment() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = await AuthService().getToken();

    // Ambil data user
    final userResponse = await ApiService().getUserProfile();
    String userId = '';

    if (userResponse.statusCode == 200) {
      final userData = json.decode(userResponse.body);
      userId = userData['id'].toString();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data pengguna")));
      return;
    }

    // Validasi lokasi jika metode pengiriman Diantar
    if (selectedDeliveryMethod == 'Diantar' &&
        (latitude == null || longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih lokasi terlebih dahulu")));
      return;
    }

    // Buat order
    final url = Uri.parse('http://192.168.43.202:8000/api/orders');

    print('Membuat order...');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'user_id': userId,
        'payment_method': selectedPaymentMethod,
        'delivery_method': selectedDeliveryMethod,
        'address':
            selectedDeliveryMethod == 'Diantar' ? addressController.text : '',
        'total_price': widget.totalPrice,
        'latitude': selectedDeliveryMethod == 'Diantar' ? latitude : null,
        'longitude': selectedDeliveryMethod == 'Diantar' ? longitude : null,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      final orderData = json.decode(response.body);
      final orderId = orderData['order']['id'];

      // Kirim item pesanan
      for (var item in widget.cartItems) {
        final orderItemUrl =
            Uri.parse('http://192.168.43.202:8000/api/order-items');
        final orderItemResponse = await http.post(
          orderItemUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'order_id': orderId.toString(),
            'product_id': item.id.toString(),
            'quantity': item.quantity.toString(),
            'price': (widget.totalPrice / widget.cartItems.length).toString(),
          }),
        );

        if (orderItemResponse.statusCode != 201) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal menyimpan item pesanan")));
          return;
        }
      }

      // Tampilkan sukses
      _showSuccessSnackbar();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gagal membuat order")));
    }
  }

  Future<void> clearPaidItemsFromCart(List<CartItem> paidItems) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems');

    if (cartData != null) {
      List<dynamic> jsonList = jsonDecode(cartData);
      List<CartItem> currentItems =
          jsonList.map((e) => CartItem.fromJson(e)).toList();

      // Hapus item yang sudah dibayar
      currentItems
          .removeWhere((item) => paidItems.any((paid) => paid.id == item.id));

      // Simpan kembali ke SharedPreferences
      final String updatedCart =
          jsonEncode(currentItems.map((e) => e.toJson()).toList());
      await prefs.setString('cartItems', updatedCart);
    }
  }

  void _showSuccessSnackbar() async {
    final snackBar = const SnackBar(
      content: Text('Pesanan Anda sedang diproses!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Hapus item dari SharedPreferences langsung dari sini
    await clearPaidItemsFromCart(widget.cartItems);

    // Navigasi ke RiwayatPage setelah snackbar selesai
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RiwayatPage()),
        (Route<dynamic> route) => false,
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
        backgroundColor: const Color(0xFF016A63),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              title: const Text('Credit'),
              value: 'Credit',
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
            if (selectedPaymentMethod == 'Credit') const SizedBox(height: 20),
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
            if (selectedDeliveryMethod == 'Diantar') ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final selectedLocation = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SelectLocationPage()),
                  );

                  if (selectedLocation != null) {
                    setState(() {
                      latitude = selectedLocation['lat'];
                      longitude = selectedLocation['lng'];
                      addressController.text = selectedLocation['address'];

                      // Hitung ongkir setelah pilih lokasi
                      const officeLat = -0.3191567866067704;
                      const officeLng = 100.37675704657606;
                      const tarifPerKm = 100;

                      double distance = calculateDistanceKm(
                        officeLat,
                        officeLng,
                        latitude!,
                        longitude!,
                      );

                      ongkir = (distance * tarifPerKm)
                          .ceilToDouble(); // Update ongkir
                    });
                  }
                },
                icon: Icon(Icons.map),
                label: Text("Pilih Lokasi di Peta"),
              ),

              const SizedBox(height: 10),
              // Tampilkan alamat di bawah tombol
              TextField(
                controller: addressController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Alamat Pilihan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ongkir:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatter.format(ongkir)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pesanan:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatter.format(widget.totalPrice + ongkir)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _showConfirmationDialog, // Menampilkan dialog konfirmasi
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF016A63),
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
