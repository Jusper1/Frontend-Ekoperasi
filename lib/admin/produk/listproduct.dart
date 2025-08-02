// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ekoperasi/admin/homepage2.dart';
import 'package:ekoperasi/customer/homepage.dart';
import 'package:ekoperasi/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addproduct.dart'; // Pastikan untuk mengimpor file AddProduct

class ListProduct extends StatefulWidget {
  const ListProduct({super.key});

  @override
  State<ListProduct> createState() => _ListProductState();
}

class _ListProductState extends State<ListProduct> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('http://192.168.43.202:8000/api/products');
    final token =
        await AuthService().getToken(); // Ambil token dari AuthService

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token', // Sertakan token dalam header
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> productList = jsonResponse['data'];

          setState(() {
            products = productList.map((product) {
              return {
                'id': product['id'],
                'image_url': product['image_url'],
                'name': product['name'],
                'price': double.parse(product['price']).toStringAsFixed(0),
                'description': product['description'],
              };
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isError = true;
            isLoading = false;
          });
          print('Error: ${jsonResponse['message']}');
        }
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
        print('Error: Status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      print('Exception: $e');
    }
  }

  Future<void> _editProduct(int id, String name, double price,
      String description, String imageUrl) async {
    final url = Uri.parse('http://192.168.43.202:8000/api/products/$id');
    final token =
        await AuthService().getToken(); // Ambil token dari AuthService

    final response = await http.put(
      url,
      body: json.encode({
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl, // Include image_url if needed
      }),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token', // Sertakan token dalam header
      },
    );

    if (response.statusCode == 200) {
      fetchProducts(); // Refresh list after editing
    } else {
      print(
          'Failed to update product: ${response.statusCode} ${response.body}');
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    TextEditingController nameController =
        TextEditingController(text: product['name']);
    TextEditingController priceController =
        TextEditingController(text: product['price']);
    TextEditingController descriptionController =
        TextEditingController(text: product['description']);
    TextEditingController imageUrlController = TextEditingController(
        text: product['image_url']); // New controller for image URL

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Edit Produk',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Produk'),
              ),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi Produk'),
              ),
              TextField(
                controller: imageUrlController, // New input for image URL
                decoration: const InputDecoration(labelText: 'URL Gambar'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () {
                _editProduct(
                  product['id'],
                  nameController.text,
                  double.parse(priceController.text),
                  descriptionController.text,
                  imageUrlController.text, // Pass the image URL
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int index) {
    // Tampilkan dialog konfirmasi sebelum menghapus produk
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Konfirmasi Penghapusan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          ),
          content: const Text("Apakah Anda yakin ingin menghapus produk ini?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Batal"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog jika batal
              },
            ),
            TextButton(
              child: const Text("Hapus"),
              onPressed: () async {
                final productId = products[index]['id']; // Ambil ID produk
                final url = Uri.parse(
                    'http://192.168.43.202:8000/api/products/$productId');
                final token = await AuthService()
                    .getToken(); // Ambil token dari AuthService

                final response = await http.delete(
                  url,
                  headers: {
                    'Authorization':
                        'Bearer $token', // Sertakan token dalam header
                  },
                );

                if (response.statusCode == 200) {
                  setState(() {
                    products.removeAt(index); // Hapus produk dari daftar
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Produk berhasil dihapus")),
                  );
                } else {
                  print(
                      'Gagal menghapus produk: ${response.statusCode} ${response.body}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menghapus produk")),
                  );
                }
                // Tutup dialog konfirmasi
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProduct()),
    ).then((_) => fetchProducts());
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedPrice =
        formatter.format(int.tryParse(product['price']) ?? 0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Image not found'));
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama produk
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Harga produk
                    Text(
                      'Rp. $formattedPrice',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Deskripsi produk
                    Text(
                      product['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tombol Edit dan Delete
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditProductDialog(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(index),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              // Ambil token dan role pengguna dari SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? role = prefs.getString('role');
              String? userName = prefs.getString('name');

              // Navigasi ke halaman awal sesuai role
              Navigator.popUntil(context, (route) => route.isFirst);

              if (role == 'admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage2(userName: userName ?? ''),
                  ),
                );
              } else if (role == 'customer') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(userName: userName ?? ''),
                  ),
                );
              }
            }),
        title: const Text('Produk',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF67C6A3),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? const Center(child: Text('Error loading products'))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index], index);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        tooltip: 'Tambah Produk',
        // ignore: sort_child_properties_last
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF67C6A3),
      ),
    );
  }
}
