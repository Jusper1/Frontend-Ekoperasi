// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekoperasi/customer/produk/pembayaran.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CartPage extends StatefulWidget {
  // ignore: use_super_parameters
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  final formatter = NumberFormat('#,###', 'id_ID');
  Set<int> checkedItems = {};
  bool isLoading = true; // Tambahkan variabel loading
  bool isError = false; // Tambahkan variabel error

  @override
  void initState() {
    super.initState();
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems');
    if (cartData != null) {
      List<dynamic> jsonList = jsonDecode(cartData);
      setState(() {
        cartItems = jsonList.map((item) => CartItem.fromJson(item)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false; // Stop loading when there's no cart data
      });
    }
  }

  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartData =
        jsonEncode(cartItems.map((item) => item.toJson()).toList());
    await prefs.setString('cartItems', cartData);
  }

  Future<void> removeItemFromServer(int index) async {
    final token =
        await AuthService().getToken(); // Ambil token dari AuthService
    final itemId =
        cartItems[index].id; // Gantilah ini dengan ID produk yang sesuai

    final url = Uri.parse(
        'http://192.168.43.202:8000/api/cart/remove/$itemId'); // Ganti dengan URL yang sesuai

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('Item removed from server');
    } else {
      print('Failed to remove item from server: ${response.statusCode}');
    }
  }

  void removeItem(int index) {
    setState(() {
      removeItemFromServer(index); // Hapus dari server
      cartItems.removeAt(index);
      saveCartItems();
    });
  }

  double calculateTotalPrice() {
    return checkedItems.fold(0, (total, index) {
      final item = cartItems[index];
      return total + (item.price * item.quantity);
    });
  }

  void navigateToPaymentPage() {
    List<CartItem> selectedItems = [];

    for (int index in checkedItems) {
      selectedItems.add(cartItems[index]); // Menggunakan CartItem
    }

    double totalPrice = calculateTotalPrice();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PembayaranPage(
          cartItems: selectedItems, // Mengirimkan item yang dipilih
          totalPrice: totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return const Center(
          child: Text('Terjadi kesalahan saat memuat data keranjang.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Saya',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF67C4A7),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView.builder(
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            final item = cartItems[index];
            final formattedPrice = formatter.format(item.price);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: checkedItems.contains(index),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            checkedItems.add(index);
                          } else {
                            checkedItems.remove(index);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Image.network(item.image_url,
                              width: 60, height: 60, fit: BoxFit.cover),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal)),
                              Text('Rp $formattedPrice',
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                              Text('x${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeItem(index),
                    ),
                  ],
                ),
              ),
            );
          }),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Harga:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Rp ${formatter.format(calculateTotalPrice())}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (checkedItems.isNotEmpty) {
                  navigateToPaymentPage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Silakan pilih item untuk dibayar")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF67C4A7),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(4.0), // Mengatur radius menjadi 4.0
                ),
              ),
              child: const Text(
                'Pembayaran',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final String image_url;
  final String name;
  final double price;
  final int quantity;
  final int id; // Tambahkan id produk

  CartItem({
    required this.image_url,
    required this.name,
    required this.price,
    required this.quantity,
    required this.id, // Tambahkan id ke konstruktor
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      image_url: json['image_url'],
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'],
      id: json['id'], // Ambil id dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': image_url,
      'name': name,
      'price': price,
      'quantity': quantity,
      'id': id, // Sertakan id saat menyimpan ke JSON
    };
  }
}
