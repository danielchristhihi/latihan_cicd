import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uts_flutter/add_product.dart';

class ProductsPage extends StatelessWidget {
  final DocumentReference storeRef = FirebaseFirestore.instance.doc('stores/2');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produk Toko'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Tambah Produk",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('store_ref', isEqualTo: storeRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada produk'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final data = productDoc.data() as Map<String, dynamic>;
              final stock = data['stock'] ?? 0;

              return ListTile(
                title: Text(data['name'] ?? 'Tanpa Nama Produk'),
                subtitle: Text('Stok: $stock'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditDialog(
                          context,
                          productDoc.id,
                          data['name'],
                          stock.toString(),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Hapus Produk'),
                            content: Text('Yakin ingin menghapus produk ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(productDoc.id)
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String productId,
    String currentName,
    String currentStock,
  ) {
    final TextEditingController _nameController =
        TextEditingController(text: currentName);
    final TextEditingController _stockController =
        TextEditingController(text: currentStock);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nama Produk'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _stockController,
              decoration: InputDecoration(labelText: 'Jumlah Stok'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newStock = int.tryParse(_stockController.text.trim()) ?? 0;

              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .update({
                  'name': newName,
                  'stock': newStock,
                });
              }

              Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
