import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MutationPage extends StatefulWidget {
  @override
  _MutationPageState createState() => _MutationPageState();
}

class _MutationPageState extends State<MutationPage> {
  final List<String> items = ['Barang A', 'Barang B', 'Barang C'];
  final List<String> warehouses = ['Gudang 1', 'Gudang 2', 'Gudang 3'];
  
  List<DocumentSnapshot> itemOptions = [];
  List<DocumentSnapshot> fromWarehouseOptions = [];
  List<DocumentSnapshot> toWarehouseOptions = [];
  String? selectedItem;
  String? fromWarehouse;
  String? toWarehouse;
  final TextEditingController quantityController = TextEditingController();

  Future<void> submitMutation() async {
    if (selectedItem == null || fromWarehouse == null || toWarehouse == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon lengkapi semua data')));
      return;
    }

    if (fromWarehouse == toWarehouse) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gudang asal dan tujuan tidak boleh sama')));
      return;
    }

    final int? qty = int.tryParse(quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jumlah harus angka yang valid')));
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final productRef = firestore.doc(selectedItem!);
      final fromWarehouseRef = firestore.doc(fromWarehouse!);
      final toWarehouseRef = firestore.doc(toWarehouse!);

      final fromStockQuery = await firestore
          .collection('warehousesStock')
          .where('product_ref', isEqualTo: productRef)
          .where('warehouse_ref', isEqualTo: fromWarehouseRef)
          .limit(1)
          .get();

      if (fromStockQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok tidak ditemukan di gudang asal')));
        return;
      }

      final fromDoc = fromStockQuery.docs.first;
      final fromData = fromDoc.data();
      final currentFromStock = fromData['stock'] ?? 0;

      if (currentFromStock < qty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok gudang asal tidak mencukupi')));
        return;
      }

      await firestore.runTransaction((transaction) async {
        // kurangi stock
        final newFromStock = currentFromStock - qty;
        transaction.update(fromDoc.reference, {'stock': newFromStock});

        final toStockQuery = await firestore
            .collection('warehousesStock')
            .where('product_ref', isEqualTo: productRef)
            .where('warehouse_ref', isEqualTo: toWarehouseRef)
            .limit(1)
            .get();

        if (toStockQuery.docs.isEmpty) {
          final newDoc = firestore.collection('warehousesStock').doc();
          transaction.set(newDoc, {
            'product_ref': productRef,
            'warehouse_ref': toWarehouseRef,
            'stock': qty,
          });
        } else {
          final toDoc = toStockQuery.docs.first;
          final toData = toDoc.data();
          final currentToStock = toData['stock'] ?? 0;
          final newToStock = currentToStock + qty;
          transaction.update(toDoc.reference, {'stock': newToStock});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mutasi berhasil dilakukan')),
      );

      setState(() {
        selectedItem = null;
        fromWarehouse = null;
        toWarehouse = null;
        quantityController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchWarehouses();
  }

  Future<void> _fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('code');

    if (code == null) return;

    DocumentReference storeRef = FirebaseFirestore.instance
        .doc(code == '22100036' ? 'stores/2' : 'stores/default');

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('store_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      itemOptions = snapshot.docs;
    });
  }

  Future<void> _fetchWarehouses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('code');

    if (code == null) return;

    DocumentReference storeRef = FirebaseFirestore.instance
        .doc(code == '22100036' ? 'stores/2' : 'stores/default');

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('warehouses')
        .where('store_ref', isEqualTo: storeRef)
        .get();

    setState(() {
      fromWarehouseOptions = snapshot.docs;
      toWarehouseOptions = snapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mutasi Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Pilih Barang'),
              value: selectedItem,
              items: itemOptions.map((doc) {
                String id = doc.id;
                String name = doc.get('name');
                return DropdownMenuItem(value: 'products/$id', child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => selectedItem = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Gudang Asal'),
              value: fromWarehouse,
              items: fromWarehouseOptions.map((doc) {
                String id = doc.id;
                String name = doc.get('name');
                return DropdownMenuItem(value: 'warehouses/$id', child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => fromWarehouse = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Gudang Tujuan'),
              value: toWarehouse,
              items: toWarehouseOptions.map((doc) {
                String id = doc.id;
                String name = doc.get('name');
                return DropdownMenuItem(value: 'warehouses/$id', child: Text(name));
              }).toList(),
              onChanged: (value) => setState(() => toWarehouse = value),
            ),
            SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitMutation,
              child: Text('Kirim Mutasi'),
            ),
          ],
        ),
      ),
    );
  }
}