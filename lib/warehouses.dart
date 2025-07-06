import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uts_flutter/add_warehouse.dart';

class WarehousesPage extends StatelessWidget {
  final DocumentReference storeRef = FirebaseFirestore.instance.doc('stores/2');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Warehouse Toko'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Tambah Warehouse",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddWarehousePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warehouses')
            .where('store_ref', isEqualTo: storeRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada warehouse untuk stores/2'));
          }

          final warehouses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: warehouses.length,
            itemBuilder: (context, index) {
              final warehouseDoc = warehouses[index];
              final warehouseData = warehouseDoc.data() as Map<String, dynamic>;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('warehousesStock')
                    .where('warehouse_ref',
                        isEqualTo: FirebaseFirestore.instance
                            .doc('warehouses/${warehouseDoc.id}'))
                    .get(),
                builder: (context, stockSnapshot) {
                  if (!stockSnapshot.hasData) {
                    return ListTile(
                      title: Text(warehouseData['name'] ?? 'Tanpa Nama'),
                      subtitle: Text('Memuat stok...'),
                    );
                  }

                  final stockDocs = stockSnapshot.data!.docs;
                  final totalStock = stockDocs.fold<double>(
                    0,
                    (sum, doc) => sum + (doc.get('stock') ?? 0),
                  );

                  return ExpansionTile(
                    title: Text(warehouseData['name'] ?? 'Tanpa Nama'),
                    subtitle: Text('Total Stock: $totalStock'),
                    children: stockDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final productRef = data['product_ref'] as DocumentReference;
                      final stockQty = data['stock'] ?? 0;

                      return FutureBuilder<DocumentSnapshot>(
                        future: productRef.get(),
                        builder: (context, productSnapshot) {
                          if (!productSnapshot.hasData) {
                            return ListTile(
                              title: Text('Memuat produk...'),
                            );
                          }

                          final productData = productSnapshot.data!.data()
                              as Map<String, dynamic>?;

                          final productName = productData?['name'] ?? 'Tanpa Nama Produk';

                          return ListTile(
                            title: Text(productName),
                            trailing: Text('Stok: $stockQty'),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}