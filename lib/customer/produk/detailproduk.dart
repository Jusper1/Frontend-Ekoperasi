import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekoperasi/customer/produk/keranjang.dart';
import 'package:ekoperasi/customer/produk/pembayaran.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailProduct extends StatefulWidget {
  final int id;
  final String image_url;
  final String name;
  final String price;
  final String description;
  final int stock_quantity;

  const DetailProduct({
    Key? key,
    required this.id,
    required this.image_url,
    required this.name,
    required this.price,
    required this.description,
    required this.stock_quantity,
  }) : super(key: key);

  @override
  State<DetailProduct> createState() => _DetailProductState();
}

class _DetailProductState extends State<DetailProduct> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedPrice = formatter.format(int.tryParse(widget.price) ?? 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF016A63),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.image_url,
                fit: BoxFit.cover,
              ),
            ),

            // Nama produk
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Harga dan stok
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp. $formattedPrice',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stok: ${widget.stock_quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.stock_quantity > 0
                                ? Colors.grey
                                : Colors.red,
                            fontWeight: widget.stock_quantity == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Deskripsi Produk
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Counter + Tombol Aksi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Counter
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 1) _quantity--;
                                });
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  if (_quantity < widget.stock_quantity) {
                                    _quantity++;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Maksimal pembelian ${widget.stock_quantity}',
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Keranjang
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF016A63),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.stock_quantity == 0
                              ? null
                              : () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  List<CartItem> cartItems = [];
                                  final cartData = prefs.getString('cartItems');

                                  if (cartData != null) {
                                    List<dynamic> jsonList =
                                        jsonDecode(cartData);
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
                                        .toList()),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Produk berhasil ditambahkan ke keranjang'),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Keranjang',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Beli Sekarang
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFBFBF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: widget.stock_quantity == 0
                              ? null
                              : () {
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
                          child: const Text(
                            'Beli Sekarang',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
