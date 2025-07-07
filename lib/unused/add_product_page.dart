import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSimpleProductPage extends StatefulWidget {
  final DocumentReference storeRef;

  AddSimpleProductPage({required this.storeRef});

  @override
  _AddSimpleProductPageState createState() => _AddSimpleProductPageState();
}

class _AddSimpleProductPageState extends State<AddSimpleProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (name.isNotEmpty) {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'stock': stock,
        'store_ref': widget.storeRef, // relasi ke toko
      });
      Navigator.pop(context); // Kembali setelah simpan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Produk'),
                validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
