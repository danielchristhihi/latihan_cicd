import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Inisialisasi Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Mengakses Firestore
import 'add_receipt.dart'; // Halaman untuk tambah transaksi

void main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp();
  // Menjalankan aplikasi utama
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Root widget aplikasi
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Penerimaan Barang',
      home: HomePage(), // Menampilkan halaman utama
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
    );
  }
}

class HomePage extends StatelessWidget {
  // Referensi ke koleksi Firestore
  final CollectionReference transactions =
      FirebaseFirestore.instance.collection('transactions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Penerimaan Barang')),
      body: StreamBuilder<QuerySnapshot>(
        // Mendengarkan perubahan data secara realtime
        stream: transactions.orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Jika terjadi error
            return Center(child: Text('Terjadi kesalahan'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Saat loading data
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            // Jika belum ada data
            return Center(child: Text('Belum ada transaksi'));
          }

          // Menampilkan data dalam ListView
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['no_form'] ?? 'Tanpa No.'),
                subtitle: Text('Tanggal: ${(data['created_at'] as Timestamp).toDate()}'),
              );
            },
          );
        },
      ),
      // Tombol tambah transaksi
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigasi ke halaman tambah
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionPage()),
          );
        },
      ),
    );
  }
}
