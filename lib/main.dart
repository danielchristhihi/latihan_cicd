import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_flutter/firebase_options.dart';
import 'package:uts_flutter/add_transaction_page.dart';
import 'package:uts_flutter/edit_transaction_page.dart';
import 'package:uts_flutter/transaction_details_page.dart';
import 'package:uts_flutter/products.dart';
import 'package:uts_flutter/suppliers.dart';
import 'package:uts_flutter/warehouses.dart';
import 'package:uts_flutter/stock_report.dart';
import 'shipment_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey('code') || !prefs.containsKey('name')) {
    await prefs.setString('code', '22100036');
    await prefs.setString('name', 'toko_daniel');
  }

  String? code = prefs.getString('code');
  String? name = prefs.getString('name');
  print('$code');
  print('$name');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Penerimaan Barang',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('purchaseGoodsReceipts');

  String? _code;
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<String> _getNameFromReference(DocumentReference? ref) async {
    if (ref == null) return '-';
    try {
      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? '-';
      }
    } catch (e) {
      print('Error getting name from reference: $e');
    }
    return '-';
  }

  Future<Map<String, String>> _getNames(Map<String, dynamic> data) async {
    final storeRef = data['store_ref'] as DocumentReference?;
    final supplierRef = data['supplier_ref'] as DocumentReference?;
    final warehouseRef = data['warehouse_ref'] as DocumentReference?;

    final storeName = await _getNameFromReference(storeRef);
    final supplierName = await _getNameFromReference(supplierRef);
    final warehouseName = await _getNameFromReference(warehouseRef);

    return {
      'store': storeName,
      'supplier': supplierName,
      'warehouse': warehouseName,
    };
  }

  Future<void> _loadStoreInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _code = prefs.getString('code');
      _name = prefs.getString('name');
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final transactionRef = FirebaseFirestore.instance
          .collection('purchaseGoodsReceipts')
          .doc(transactionId);

      final detailsSnapshot = await transactionRef.collection('details').get();

      for (var doc in detailsSnapshot.docs) {
        final detailData = doc.data();
        final productRef = detailData['product_ref'] as DocumentReference?;
        final qty = detailData['qty'] as num? ?? 0;

        // Kurangi stok produk jika referensi ada
        if (productRef != null) {
          final productDoc = await productRef.get();
          if (productDoc.exists) {
            final productData = productDoc.data() as Map<String, dynamic>;
            final currentStock = productData['stock'] as num? ?? 0;

            // Update stock: kurangi stok
            await productRef.update({
              'stock': currentStock - qty,
            });
          }
        }

        // Hapus detail transaksi
        await doc.reference.delete();
      }

      // Hapus dokumen utama transaksi
      await transactionRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi & stok berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Penerimaan Barang"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Tambah Transaksi",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTransactionPage()),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShipmentHomePage()),
              );
            },
            child: Text('Pengiriman'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductsPage()),
              );
            },
            child: Text('Produk'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SuppliersPage()),
              );
            },
            child: Text('Supplier'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WarehousesPage()),
              );
            },
            child: Text('Warehouse'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StockReportPage()),
              );
            },
            child: Text('Stock Report'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_code != null && _name != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Toko: $_name (Code: $_code)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: notes
                  //.where('store_code', isEqualTo: '22100036')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Belum ada transaksi."));
                }

                return ListView(
                  children: snapshot.data!.docs
                    .where((doc) => (doc.data()! as Map<String, dynamic>)['store_code'] == '22100036')
                    .map((DocumentSnapshot document) {
                      final data = document.data()! as Map<String, dynamic>;

                      return FutureBuilder<Map<String, String>>(
                        future: _getNames(data),
                        builder: (context, snapshotRef) {
                          if (!snapshotRef.hasData) {
                            return ListTile(title: Text('Memuat...'));
                          }

                          final names = snapshotRef.data!;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(data['no_form'] ?? '-'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tanggal: ${data['created_at'] != null ? (data['created_at'] as Timestamp).toDate().toString() : '-'}'),
                                  Text('Total: ${data['grandtotal']?.toString() ?? '-'}'),
                                  Text('Jumlah Item: ${data['item_total']?.toString() ?? '-'}'),
                                  Text('Tanggal Posting: ${data['post_date'] ?? '-'}'),
                                  Text('Store: ${names['store'] ?? '-'}'),
                                  Text('Supplier: ${names['supplier'] ?? '-'}'),
                                  Text('Warehouse: ${names['warehouse'] ?? '-'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit Transaksi',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditTransactionPage(transactionId: document.id),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Hapus Transaksi',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Konfirmasi"),
                                          content: Text("Yakin ingin menghapus transaksi ini beserta detailnya?"),
                                          actions: [
                                            TextButton(
                                              child: Text("Batal"),
                                              onPressed: () => Navigator.pop(context, false),
                                            ),
                                            ElevatedButton(
                                              child: Text("Hapus"),
                                              onPressed: () => Navigator.pop(context, true),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await deleteTransaction(document.id);
                                      }
                                    },
                                  ),
                                  data['synced'] == true
                                      ? Icon(Icons.cloud_done, color: Colors.green)
                                      : Icon(Icons.cloud_off, color: Colors.grey),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionDetailsPage(transactionId: document.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// String _getPath(dynamic ref) {
//   if (ref == null) return '-';
//   try {
//     if (ref is DocumentReference) {
//       return ref.path;
//     } else {
//       return ref.toString(); // fallback untuk _JsonDocumentReference
//     }
//   } catch (e) {
//     return '-';
//   }
// }