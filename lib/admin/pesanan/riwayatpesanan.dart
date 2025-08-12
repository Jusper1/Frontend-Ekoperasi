// ignore_for_file: use_super_parameters, avoid_print

import 'package:ekoperasi/admin/akun/akuncustomer.dart';
import 'package:ekoperasi/admin/homepage2.dart';
import 'package:ekoperasi/admin/pesanan/listpesanan.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List orders = [];
  Map<int, String> userMap = {};
  bool isLoadingOrders = true;
  String? token;
  String searchQuery = '';
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    fetchToken();
  }

  Future<void> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    if (token != null) {
      await fetchUsers();
      fetchOrders();
    } else {
      print('Token not found');
    }
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('http://192.168.43.202:8000/api/users');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List rawUsers = json.decode(response.body);
      setState(() {
        userMap = {for (var user in rawUsers) user['id']: user['name']};
      });
    } else {
      print('Failed to load users: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> fetchOrders() async {
    final url = Uri.parse('http://192.168.43.202:8000/api/orders');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List rawOrders = json.decode(response.body);
      setState(() {
        orders = rawOrders
            .where((order) =>
                order['status'] == 'completed' || order['status'] == 'canceled')
            .map((order) {
          order['user_name'] = userMap[order['user_id']] ?? 'Tidak Diketahui';
          return order;
        }).toList();
        isLoadingOrders = false;
      });
    } else {
      print('Failed to load orders: ${response.statusCode} ${response.body}');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const HomePage2(userName: 'NamaUser')),
            (route) => false);
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ListPesananPage()),
            (route) => false);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AccountPage1()),
            (route) => false);
        break;
    }
  }

  List filterOrders(String query) {
    if (query.isEmpty) {
      return orders;
    }
    return orders.where((order) {
      final id = order['id'].toString().toLowerCase();
      final userName = order['user_name'].toLowerCase();
      final status = order['status'].toLowerCase();
      final totalPrice = order['total_price'].toString().toLowerCase();
      return id.contains(query.toLowerCase()) ||
          userName.contains(query.toLowerCase()) ||
          status.contains(query.toLowerCase()) ||
          totalPrice.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF016A63),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 30),
            onPressed: () {
              showSearch(
                  context: context, delegate: OrderSearchDelegate(orders));
            },
          ),
        ],
      ),
      body: isLoadingOrders
          ? const Center(child: CircularProgressIndicator())
          : OrderList(orders: filterOrders(searchQuery)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_checkout_outlined),
              label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

class OrderList extends StatelessWidget {
  final List orders;

  const OrderList({required this.orders, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? const Center(
            child: Text('Tidak ada pesanan.',
                style: TextStyle(fontSize: 18, color: Colors.grey)))
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  title: Text('Order ID: ${order['id']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama: ${order['user_name']}',
                          style: const TextStyle(fontSize: 14)),
                      Text('Total Harga: Rp ${order['total_price']}',
                          style: const TextStyle(fontSize: 14)),
                      Text('Status: ${order['status']}',
                          style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(order['status']))),
                    ],
                  ),
                  onTap: () {
                    // Implement your order detail navigation here if necessary.
                  },
                ),
              );
            },
          );
  }

  Color _getStatusColor(String status) {
    if (status == 'completed') {
      return Colors.green;
    } else if (status == 'canceled') {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}

class OrderSearchDelegate extends SearchDelegate {
  final List orders;

  OrderSearchDelegate(this.orders);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredOrders = orders.where((order) {
      final id = order['id'].toString().toLowerCase();
      final userName = order['user_name'].toLowerCase();
      final status = order['status'].toLowerCase();
      final totalPrice = order['total_price'].toString().toLowerCase();
      return id.contains(query.toLowerCase()) ||
          userName.contains(query.toLowerCase()) ||
          status.contains(query.toLowerCase()) ||
          totalPrice.contains(query.toLowerCase());
    }).toList();

    return OrderList(orders: filteredOrders);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return OrderList(orders: orders);
  }
}
