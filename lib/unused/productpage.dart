import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_page.dart';

class SimpleProductsPage extends StatelessWidget {
  // Referensi toko tetap (contoh: toko dengan ID 2)
  final DocumentReference storeRef = FirebaseFirestore.instance.doc('stores/2');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigasi ke halaman tambah produk
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddSimpleProductPage(storeRef: storeRef)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ambil data produk berdasarkan store yang aktif
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
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? 'Tanpa Nama'),
                subtitle: Text('Stok: ${data['stock'] ?? 0}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditDialog(context, doc.id, data['name'], data['stock']);
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
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(doc.id)
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

  // Fungsi dialog untuk mengedit produk
  void _showEditDialog(BuildContext context, String id, String currentName, int currentStock) {
    final nameController = TextEditingController(text: currentName);
    final stockController = TextEditingController(text: currentStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: stockController,
              decoration: InputDecoration(labelText: 'Stok'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final stock = int.tryParse(stockController.text.trim()) ?? 0;

              if (name.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(id)
                    .update({'name': name, 'stock': stock});
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
