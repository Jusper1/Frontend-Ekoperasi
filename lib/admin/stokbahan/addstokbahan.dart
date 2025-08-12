// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ekoperasi/admin/stokbahan/liststokbahan.dart';

class AddStokBahan extends StatefulWidget {
  // ignore: use_super_parameters
  const AddStokBahan({Key? key}) : super(key: key);

  @override
  State<AddStokBahan> createState() => _AddStokBahanState();
}

class _AddStokBahanState extends State<AddStokBahan> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _supplierController = TextEditingController();

  String _selectedUnit = 'kg'; // Default unit
  String _errorMessage = '';

  final List<String> _units = ['kg', 'liter', 'pcs']; // List of available units

  // Function to save stock data to the API
  Future<void> _saveStock() async {
    if (_nameController.text.isEmpty ||
        _stockQuantityController.text.isEmpty ||
        _purchasePriceController.text.isEmpty ||
        _supplierController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Semua field harus diisi!';
      });
    } else {
      setState(() {
        _errorMessage = '';
      });

      final url = Uri.parse('http://192.168.43.202:8000/api/stokbahan/create');
      final response = await http.post(
        url,
        body: json.encode({
          'name': _nameController.text,
          'stock_quantity': double.parse(_stockQuantityController.text),
          'unit': _selectedUnit,
          'purchase_price': double.parse(_purchasePriceController.text),
          'supplier': _supplierController.text,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 201) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok bahan berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ListStokBahan()),
          (route) => false, // Menghapus semua rute sebelumnya
        ); // Navigate back after adding
      } else {
        // ignore: avoid_print
        print('Failed to create stok bahan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan stok bahan!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        title: const Text('Tambah Stok Bahan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF016A63),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),

              // Input for Nama Bahan
              const Text(
                'Nama Bahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Nama Bahan',
                  hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),

              // Input for Jumlah Stok
              const Text(
                'Jumlah Stok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stockQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan Jumlah Stok',
                  hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown for Satuan
              const Text(
                'Satuan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedUnit,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUnit = newValue!;
                  });
                },
                items: _units.map<DropdownMenuItem<String>>((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(
                      unit,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.normal),
                    ),
                  );
                }).toList(),
                isExpanded: true,
              ),
              const SizedBox(height: 20),

              // Input for Harga Pembelian
              const Text(
                'Harga Pembelian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan Harga Pembelian',
                  hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),

              // Input for Pemasok
              const Text(
                'Pemasok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _supplierController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Nama Pemasok',
                  hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveStock,
                  // ignore: sort_child_properties_last
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF016A63), // Button color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical:
                            20), // Adjust padding to make the button wider
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
