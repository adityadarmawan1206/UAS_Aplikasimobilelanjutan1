import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Tambahkan import ini
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = ['Mesin', 'Oli', 'Ban', 'Lampu', 'Tools'];
  bool _isLoading = false;

  Future<void> _saveProduct() async {
    // Validasi Input
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _imageUrlController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua kolom dan pilih kategori!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Ambil data user yang sedang login
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal: Anda belum login!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int stockValue = int.tryParse(_stockController.text) ?? 0;

      // Simpan data ke Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text,
        'price': _priceController.text,
        'imageUrl': _imageUrlController.text,
        'category': _selectedCategory,
        'stock': stockValue,
        'description': _descriptionController.text,
        'soldCount': 0,
        'isSoldOut': stockValue <= 0,
        'createdAt': Timestamp.now(),
        'userId':
            user.uid, // <-- INI KUNCI UTAMANYA (Biar terhubung ke info toko)
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Barang berhasil mengaspal di toko! 🏁"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.orangeAccent),
      alignLabelWithHint: true,
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "TAMBAH BARANG",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Nama Barang",
                Icons.settings_suggest,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Pilih Kategori",
                Icons.category,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.orangeAccent,
              ),
              value: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _priceController,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Harga (ex: Rp 50.000)",
                Icons.monetization_on,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Jumlah Stok (ex: 25)",
                Icons.numbers,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Deskripsi Produk",
                Icons.description,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white),
              decoration: _customInputDecoration(
                "Link Gambar (URL)",
                Icons.image,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "SIMPAN BARANG",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
