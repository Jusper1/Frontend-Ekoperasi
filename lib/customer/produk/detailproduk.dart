// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekoperasi/customer/produk/keranjang.dart';
import 'package:ekoperasi/customer/produk/pembayaran.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailProduct extends StatefulWidget {
  final int id; // Menambahkan id produk
  final String image_url; // Menggunakan camelCase untuk konsistensi
  final String name;
  final String price;
  final String description;

  // ignore: use_super_parameters
  const DetailProduct({
    Key? key,
    required this.id, // Tambahkan id ke parameter
    required this.image_url,
    required this.name,
    required this.price,
    required this.description,
  }) : super(key: key);

  @override
  State<DetailProduct> createState() => _DetailProductState();
}

class _DetailProductState extends State<DetailProduct> {
  //bool _isFavorite = false;
  int _quantity = 1; // Inisialisasi jumlah dengan 1

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedPrice = formatter.format(int.tryParse(widget.price) ?? 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF67C4A7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Gambar
            Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      widget.image_url), // Gunakan NetworkImage untuk URL
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Judul Produk dan Tombol Favorit
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // IconButton(
                  //   icon: Icon(
                  //     _isFavorite ? Icons.favorite : Icons.favorite_border,
                  //     color: _isFavorite ? Colors.red : Colors.grey,
                  //   ),
                  //   onPressed: () {
                  //     setState(() {
                  //       _isFavorite = !_isFavorite;
                  //     });
                  //   },
                  // ),
                ],
              ),
            ),
            // Harga dan Jumlah Terjual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Text(
                    'Rp. $formattedPrice',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Deskripsi Produk
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Pemilih Jumlah dan Tombol Tambah ke Keranjang
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0), // Kurangi padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_quantity > 1) {
                                _quantity--;
                              }
                            });
                          },
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Fungsi tambah keranjang
                        final prefs = await SharedPreferences.getInstance();
                        List<CartItem> cartItems = [];
                        final cartData = prefs.getString('cartItems');

                        if (cartData != null) {
                          List<dynamic> jsonList = jsonDecode(cartData);
                          cartItems = jsonList
                              .map((item) => CartItem.fromJson(item))
                              .toList();
                        }

                        cartItems.add(
                          CartItem(
                            image_url: widget.image_url,
                            name: widget.name,
                            price: double.parse(widget.price),
                            quantity: _quantity,
                            id: widget.id,
                          ),
                        );

                        prefs.setString(
                            'cartItems',
                            jsonEncode(cartItems
                                .map((item) => item.toJson())
                                .toList()));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Produk berhasil ditambahkan ke keranjang'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48), // Ukuran fleksibel
                        backgroundColor: const Color(0xFF67C4A7),
                      ),
                      child: const Text(
                        'Masukkan ke keranjang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      onPressed: () {
                        // Fungsi beli sekarang
                        final totalPrice =
                            double.parse(widget.price) * _quantity;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PembayaranPage(
                              cartItems: [
                                CartItem(
                                  image_url: widget.image_url,
                                  name: widget.name,
                                  price: double.parse(widget.price),
                                  quantity: _quantity,
                                  id: widget.id,
                                ),
                              ],
                              totalPrice: totalPrice,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFBFBF)),
                        minimumSize: const Size(120, 48), // Ukuran fleksibel
                      ),
                      child: const Text(
                        'Beli Sekarang',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
