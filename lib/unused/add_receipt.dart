import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Akses Firestore

class AddTransactionPage extends StatefulWidget {
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  // Key untuk form validasi
  final _formKey = GlobalKey<FormState>();
  // Controller untuk input nomor form
  final TextEditingController _noFormController = TextEditingController();

  // Fungsi untuk menyimpan data ke Firestore
  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Menambahkan data baru ke koleksi 'transactions'
      await FirebaseFirestore.instance.collection('transactions').add({
        'no_form': _noFormController.text,
        'created_at': Timestamp.now(), // Waktu saat data dibuat
      });
      // Kembali ke halaman utama setelah simpan
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign form key
          child: Column(
            children: [
              // Input nomor form
              TextFormField(
                controller: _noFormController,
                decoration: InputDecoration(labelText: 'Nomor Form'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 20),
              // Tombol simpan
              ElevatedButton(
                onPressed: _saveTransaction,
                child: Text('Simpan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
