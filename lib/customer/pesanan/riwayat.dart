// ignore_for_file: avoid_print, use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with SingleTickerProviderStateMixin {
  List orders = [];
  String? token;
  String? userId; // Menyimpan user_id
  bool isLoadingOrders = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchToken();
  }

  Future<void> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');

    // Ambil user_id sebagai int dan ubah ke String
    int? userIdInt = prefs.getInt('user_id');
    userId = userIdInt?.toString(); // Konversi ke String jika tidak null

    if (token != null && userId != null) {
      fetchOrders();
    } else {
      print('Token atau user_id tidak ditemukan');
    }
  }

  Future<void> fetchOrders({String? status}) async {
    final url = Uri.parse('http://192.168.43.202:8000/api/orders/user_id');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId, // Mengirimkan user_id secara otomatis
          if (status != null) 'status': status, // Kirim status jika ada
        }),
      );

      if (response.statusCode == 200) {
        final List rawOrders = json.decode(response.body);
        setState(() {
          orders = rawOrders;
          isLoadingOrders = false;
        });
      } else {
        print('Gagal memuat pesanan: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  Future<void> afterLogin() async {
    await fetchToken(); // Mengambil token dan user_id dari SharedPreferences
    await fetchOrders(); // Memuat semua pesanan berdasarkan user_id
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final url =
        Uri.parse('http://192.168.43.202:8000/api/orders/$orderId/status');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        fetchOrders(); // Reload pesanan setelah status diperbarui

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diperbarui menjadi $status'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        showErrorSnackBar('Gagal memperbarui status');
      }
    } catch (e) {
      print('Error: $e');
      showErrorSnackBar('Terjadi kesalahan saat memperbarui status');
    }
  }

  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    final url = Uri.parse('http://192.168.43.202:8000/api/products/$productId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'product_name': data['data']['name'],
        'description': data['data']['description'],
        'image_url': data['data']['image_url'],
        'price': data['data']['price'],
      };
    } else {
      print('Failed to load product: ${response.statusCode} ${response.body}');
      return {
        'product_name': 'Unknown Product',
        'description': '',
        'image_url': '',
        'price': 0,
      };
    }
  }

  Future<void> fetchOrderDetails(int orderId, BuildContext context) async {
    // Fetch order details
    final url = Uri.parse('http://192.168.43.202:8000/api/orders/$orderId');

    try {
      // Get the order details including payment, delivery method, and address
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final orderDetails = json.decode(response.body);

        // Fetch order items based on orderId
        final itemsResponse = await http.get(
          Uri.parse(
              'http://192.168.43.202:8000/api/order-items?order_id=$orderId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (itemsResponse.statusCode == 200) {
          final List orderItems = json.decode(itemsResponse.body);

          // Get product details for each order item
          final itemsWithProductDetails =
              await Future.wait(orderItems.map((item) async {
            final productDetails =
                await fetchProductDetails(item['product_id']);
            return {
              ...item,
              ...productDetails,
            }; // Merge product details with order items
          }).toList());

          // Navigate to the OrderDetailPage with order details and order items
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(
                  orderDetails: orderDetails,
                  orderItems: itemsWithProductDetails),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to load order items: ${itemsResponse.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to load order details: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List filterOrdersByStatus(String status) {
    return orders.where((order) => order['status'] == status).toList();
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
        backgroundColor: const Color(0xFF67C4A7),
      ),
      body: isLoadingOrders
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontSize: 12, // Ukuran font kecil
                    fontWeight: FontWeight.normal, // Tidak bold
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize:
                        12, // Ukuran font kecil untuk tab yang tidak dipilih
                    fontWeight: FontWeight.normal, // Tidak bold
                  ),
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Process'),
                    Tab(text: 'Complete'),
                    Tab(text: 'Cancel'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      OrderList(
                        orders: filterOrdersByStatus('pending'),
                        onTap: (orderId) => fetchOrderDetails(
                            orderId, context), // Navigasi ke detail
                        onAccept: (orderId) =>
                            updateOrderStatus(orderId, 'process'),
                        onCancel: (orderId) =>
                            updateOrderStatus(orderId, 'canceled'),
                      ),
                      OrderList(
                        orders: filterOrdersByStatus('process'),
                        onTap: (orderId) => fetchOrderDetails(
                            orderId, context), // Navigasi ke detail
                        onComplete: (orderId) =>
                            updateOrderStatus(orderId, 'completed'),
                        onCancel: (orderId) =>
                            updateOrderStatus(orderId, 'canceled'),
                      ),
                      OrderList(
                        orders: filterOrdersByStatus('completed'),
                        onTap: (orderId) => fetchOrderDetails(
                            orderId, context), // Navigasi ke detail
                      ),
                      OrderList(
                        orders: filterOrdersByStatus('canceled'),
                        onTap: (orderId) => fetchOrderDetails(
                            orderId, context), // Navigasi ke detail
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class OrderList extends StatelessWidget {
  final List orders;
  final Function(int orderId)? onAccept;
  final Function(int orderId)? onComplete;
  final Function(int orderId)? onCancel;
  final Function(int orderId)? onTap;

  const OrderList({
    required this.orders,
    this.onAccept,
    this.onComplete,
    this.onCancel,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? const Center(
            child: Text(
              'Tidak ada pesanan.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return InkWell(
                onTap: () {
                  if (onTap != null) {
                    onTap!(order[
                        'id']); // Tambahkan tanda seru untuk memanggil fungsi nullable
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order['id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Harga: Rp ${order['total_price']}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tanggal Order: ${order['created_at'].substring(8, 10)}-${order['created_at'].substring(5, 7)}-${order['created_at'].substring(0, 4)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Status: ${order['status']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: order['status'] == 'canceled'
                                ? Colors.red
                                : order['status'] == 'pending'
                                    ? Colors.orange
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              if (order['status'] == 'pending' &&
                                  onCancel != null)
                                OutlinedButton(
                                  onPressed: () => onCancel!(order['id']),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Batalkan'),
                                ),
                              // if (order['status'] == 'process' &&
                              //     onCancel != null)
                              // OutlinedButton(
                              //   onPressed: () => onCancel!(order['id']),
                              //   style: OutlinedButton.styleFrom(
                              //     foregroundColor: Colors.red,
                              //     side: const BorderSide(color: Colors.red),
                              //   ),
                              //   child: const Text('Batalkan'),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderDetails;
  final List orderItems;

  const OrderDetailPage({
    required this.orderDetails,
    required this.orderItems,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        ),
        backgroundColor: const Color(0xFF67C4A7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Halaman
            const Center(
              child: Text(
                'Rincian Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            //Order ID
            // Row(
            //   children: [
            //     const Icon(Icons.pending_actions, color: Colors.orange),
            //     const SizedBox(width: 8),
            //     Expanded(
            //       child: Row(
            //         children: [
            //           const Text(
            //             'Status: ',
            //             style: TextStyle(fontSize: 14, color: Colors.black),
            //           ),
            //           Text(
            //             '${orderDetails['status']}',
            //             style:
            //                 const TextStyle(fontSize: 14, color: Colors.black),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 5),

            //Tanggal Pemesan
            // Row(
            //   children: [
            //     const Icon(Icons.calendar_month, color: Colors.greenAccent),
            //     const SizedBox(width: 8),
            //     Expanded(
            //       child: Row(
            //         children: [
            //           const Text(
            //             'Tanggal Order: ',
            //             style: TextStyle(fontSize: 14, color: Colors.black87),
            //           ),
            //           Text(
            //             '${orderDetails['created_at'].substring(8, 10)}-${orderDetails['created_at'].substring(5, 7)}-${orderDetails['created_at'].substring(0, 4)}',
            //             style: const TextStyle(
            //               fontSize: 14,
            //               color: Colors.black87,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 10),

            // Metode Pembayaran
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Metode Pembayaran: ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Text(
                        '${orderDetails['payment_method']}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metode Pengiriman
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Metode Pengiriman: ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Text(
                        '${orderDetails['delivery_method']}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Alamat Pengiriman
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Alamat: ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      Text(
                        '${orderDetails['address']}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Total Harga
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.yellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Total Harga: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Rp ${orderDetails['total_price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pesanan Customer
            const Text(
              'Pesanan Anda',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 12),

            // List Item Pesanan
            Expanded(
              child: ListView.builder(
                itemCount: orderItems.length,
                itemBuilder: (context, index) {
                  final item = orderItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          if (item['image_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item['image_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported,
                                        size: 60, color: Colors.grey),
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Icon(Icons.image_not_supported,
                                  size: 40, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jumlah: ${item['quantity']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                Text(
                                  'Harga: Rp ${item['price']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                                if (item['description'] != null &&
                                    item['description'].isNotEmpty)
                                  Text(
                                    'Deskripsi: ${item['description']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
