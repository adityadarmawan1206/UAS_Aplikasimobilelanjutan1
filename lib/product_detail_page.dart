import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'checkout_page.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  // Fungsi untuk menambah barang ke keranjang
  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('carts').add({
        'userId': user.uid,
        'productId': productId,
        'productName': productData['name'] ?? 'Produk',
        'price': productData['price'] ?? 'Rp 0',
        'imageUrl': productData['imageUrl'] ?? '',
        'quantity': 1, // Default jumlah masuk keranjang adalah 1
        'addedAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil dimasukkan ke Keranjang! 🛒"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menambah ke keranjang: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int stock = productData['stock'] ?? 0;
    String description =
        productData['description'] ?? 'Tidak ada deskripsi untuk produk ini.';

    // Mengambil ID Penjual dari data produk (Pastikan field ini ada di collection 'products' kamu!)
    String sellerId = productData['userId'] ?? productData['sellerId'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "DETAIL PRODUK",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(color: Colors.white),
              child: Image.network(
                productData['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productData['price'] ?? 'Rp 0',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productData['name'] ?? 'Nama Produk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Chip(
                        backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                        label: Text(
                          productData['category'] ?? 'Lainnya',
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Stok: $stock",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "| Terjual: ${productData['soldCount'] ?? 0}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 40),

                  // --- BAGIAN INFO TOKO (Terhubung ke Firestore Users) ---
                  FutureBuilder<DocumentSnapshot>(
                    future: sellerId.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(sellerId)
                              .get()
                        : null,
                    builder: (context, snapshot) {
                      // Nilai default jika masih loading atau data tidak ditemukan
                      String finalStoreName = 'Toko Tidak Diketahui';
                      String finalLocation = 'Lokasi Tidak Diketahui';

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final sellerData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        // Mengambil nama toko sesuai screenshot databasemu
                        finalStoreName =
                            sellerData['storeName'] ?? finalStoreName;

                        // Menggabungkan kelurahan dan province sesuai screenshot databasemu
                        String kel = sellerData['city'] ?? '';
                        String prov = sellerData['province'] ?? '';

                        if (kel.isNotEmpty && prov.isNotEmpty) {
                          finalLocation = "$kel, $prov";
                        } else if (kel.isNotEmpty) {
                          finalLocation = kel;
                        } else if (prov.isNotEmpty) {
                          finalLocation = prov;
                        }
                      }

                      return Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(
                              Icons.storefront,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  finalStoreName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Online • $finalLocation",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(
                                color: Colors.orangeAccent,
                              ),
                            ),
                            child: const Text("Kunjungi"),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 40),

                  // --- BAGIAN DESKRIPSI BARANG ---
                  const Text(
                    "Deskripsi Produk",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        color: const Color(0xFF1E1E1E),
        child: Row(
          children: [
            // TOMBOL KERANJANG
            Expanded(
              flex: 1,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.orangeAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: stock > 0 ? () => _addToCart(context) : null,
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(width: 15),

            // TOMBOL BELI SEKARANG
            Expanded(
              flex: 3,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: stock > 0
                    ? () {
                        // Format data produk ini menjadi List agar cocok dengan CheckoutPage
                        List<Map<String, dynamic>> item = [
                          {
                            'productId': productId,
                            'productName': productData['name'],
                            'price': productData['price'],
                            'imageUrl': productData['imageUrl'],
                            'quantity': 1,
                          },
                        ];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CheckoutPage(checkoutItems: item),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  stock > 0 ? "BELI SEKARANG" : "STOK HABIS",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
