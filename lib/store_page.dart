import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_detail_page.dart'; // Sesuaikan dengan nama file detail produkmu

class StorePage extends StatelessWidget {
  final String sellerId;

  const StorePage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "PROFIL TOKO",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- HEADER: INFORMASI TOKO ---
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(sellerId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  ),
                );
              }

              String storeName = 'Toko Tidak Diketahui';
              String location = 'Lokasi Tidak Diketahui';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                storeName = data['storeName'] ?? storeName;

                String kel = data['city'] ?? '';
                String prov = data['province'] ?? '';
                if (kel.isNotEmpty && prov.isNotEmpty) {
                  location = "$kel, $prov";
                } else if (kel.isNotEmpty) {
                  location = kel;
                } else if (prov.isNotEmpty) {
                  location = prov;
                }
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(
                        Icons.storefront,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // --- BODY: DAFTAR PRODUK DARI TOKO INI ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Mengambil data dari collection 'products' yang 'userId'-nya sama dengan sellerId toko ini
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('userId', isEqualTo: sellerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Toko ini belum memiliki produk.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 kolom seperti Shopee
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.7, // Mengatur tinggi card produk
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productDoc = products[index];
                    final productData =
                        productDoc.data() as Map<String, dynamic>;
                    final productId = productDoc.id;

                    return GestureDetector(
                      onTap: () {
                        // Navigasi ke detail produk saat diklik
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              productId: productId,
                              productData: productData,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar Produk
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                                child: Image.network(
                                  productData['imageUrl'] ?? '',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                ),
                              ),
                            ),
                            // Info Produk (Nama, Harga, Terjual)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['name'] ?? 'Nama Produk',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    productData['price'] ?? 'Rp 0',
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${productData['soldCount'] ?? 0} Terjual",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
