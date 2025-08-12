// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ignore: use_key_in_widget_constructors
class UnexpectedExpenseScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _UnexpectedExpenseScreenState createState() =>
      _UnexpectedExpenseScreenState();
}

class _UnexpectedExpenseScreenState extends State<UnexpectedExpenseScreen> {
  List<Map<String, dynamic>> unexpectedExpenses = [];
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String _filter = "daily";

  @override
  void initState() {
    super.initState();
    _fetchUnexpectedExpenses();
  }

  Future<void> _fetchUnexpectedExpenses() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.43.202:8000/api/unexpected-expenses?filter=$_filter'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          unexpectedExpenses = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _addUnexpectedExpense() async {
    try {
      final expenseData = {
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'date': _dateController.text,
      };

      final response = await http.post(
        Uri.parse('http://192.168.43.202:8000/api/unexpected-expenses'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expenseData),
      );

      if (response.statusCode == 201) {
        setState(() {
          unexpectedExpenses.add(expenseData);
        });
        _clearForm();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Biaya Tidak Terduga berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ));
      } else {
        throw Exception('Gagal menambahkan data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _deleteUnexpectedExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.43.202:8000/api/unexpected-expenses/$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          unexpectedExpenses.removeWhere((expense) => expense['id'] == id);
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Biaya Tidak Terduga berhasil dihapus')));
      } else {
        throw Exception('Gagal menghapus data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    _amountController.clear();
    _dateController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF016A63),
        title: const Text(
          'Biaya Tidak Terduga',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        ),
        actions: [
          DropdownButton<String>(
            value: _filter,
            items: const [
              DropdownMenuItem(
                  value: "daily",
                  child: Text("Harian",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.normal))),
              DropdownMenuItem(
                  value: "weekly",
                  child: Text(
                    "Mingguan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                  )),
              DropdownMenuItem(
                  value: "monthly",
                  child: Text(
                    "Bulanan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _filter = value!;
              });
              _fetchUnexpectedExpenses();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Input
            const Text(
              'Tambah Biaya Tidak Terduga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Harga',
                        labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _dateController,
                      readOnly:
                          true, // Supaya pengguna tidak bisa mengetik manual
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate:
                              DateTime(2000), // Tanggal awal yang bisa dipilih
                          lastDate:
                              DateTime(2100), // Tanggal akhir yang bisa dipilih
                        );

                        if (pickedDate != null) {
                          // Format tanggal menjadi YYYY-MM-DD
                          String formattedDate =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                          // Set nilai ke controller
                          _dateController.text = formattedDate;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addUnexpectedExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF016A63), // Button color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical:
                                20, // Adjust padding to make the button wider
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Tambahkan Biaya',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List of Expenses
            const Text(
              'Daftar Biaya Tidak Terduga',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...unexpectedExpenses.map((expense) {
              return Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(
                        expense['description'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(expense['date']))}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rp ${expense['amount']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteUnexpectedExpense(expense['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                ],
              );
              // ignore: unnecessary_to_list_in_spreads
            }).toList(),
          ],
        ),
      ),
    );
  }
}
