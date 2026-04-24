import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String userRole = 'pembeli';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (mounted) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'pembeli';
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- KUMPULAN FUNGSI AKSI STATUS PESANAN ---

  // Penjual: Konfirmasi Pesanan Baru (Stok berkurang disini)
  Future<void> _confirmOrder(
    String transactionId,
    String productId,
    int quantity,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .update({'status': 'Dikemas'});

      // Potong stok dan tambah terjual
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
            'stock': FieldValue.increment(-quantity),
            'soldCount': FieldValue.increment(quantity),
          });

      _showMessage("Pesanan berhasil dikonfirmasi (Dikemas)", Colors.green);
    } catch (e) {
      _showMessage("Gagal: $e", Colors.redAccent);
    }
  }

  // Penjual: Kirim Barang
  Future<void> _sendOrder(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .update({'status': 'Dikirim'});
      _showMessage("Pesanan berstatus Dikirim", Colors.green);
    } catch (e) {
      _showMessage("Gagal: $e", Colors.redAccent);
    }
  }

  // Pembeli: Pesanan Diterima (Selesai)
  Future<void> _completeOrder(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .update({'status': 'Selesai'});
      _showMessage("Pesanan Selesai! Terima kasih.", Colors.green);
    } catch (e) {
      _showMessage("Gagal: $e", Colors.redAccent);
    }
  }

  // Pembeli: Ajukan Pembatalan (Input Alasan)
  Future<void> _requestCancel(String transactionId) async {
    TextEditingController reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Alasan Pembatalan",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Masukkan alasan...",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orangeAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                if (reasonController.text.isEmpty) return;
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(transactionId)
                      .update({
                        'status': 'Menunggu Pembatalan',
                        'cancelReason': reasonController.text,
                      });
                  _showMessage(
                    "Pengajuan pembatalan terkirim",
                    Colors.orangeAccent,
                  );
                } catch (e) {
                  _showMessage("Gagal: $e", Colors.redAccent);
                }
              },
              child: const Text("Kirim", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Penjual: Setujui Pembatalan (Stok tidak dipotong karena dibatalkan sebelum dikemas)
  Future<void> _approveCancel(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .update({'status': 'Dibatalkan'});
      _showMessage("Pembatalan Disetujui", Colors.green);
    } catch (e) {
      _showMessage("Gagal: $e", Colors.redAccent);
    }
  }

  void _showMessage(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  // --- UI BAGIAN STATUS CHIP ---
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (status) {
      case 'Menunggu':
        bgColor = Colors.orange.shade700;
        break;
      case 'Dikemas':
        bgColor = Colors.blue.shade700;
        break;
      case 'Dikirim':
        bgColor = Colors.purple.shade600;
        break;
      case 'Selesai':
        bgColor = Colors.green.shade700;
        break;
      case 'Menunggu Pembatalan':
        bgColor = Colors.red.shade400;
        break;
      case 'Dibatalkan':
        bgColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "PESANAN",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Berlangsung"),
            Tab(text: "Selesai"),
            Tab(text: "Dibatalkan"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          var allDocs = snapshot.data!.docs;

          // Filter Data: Jika pembeli, hanya tampilkan miliknya. Jika penjual, tampilkan semua.
          var filteredDocs = allDocs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (userRole == 'penjual') return true;
            return data['buyerId'] == currentUser?.uid;
          }).toList();

          // Pisahkan berdasarkan Tab
          var berlangsungDocs = filteredDocs.where((doc) {
            String status = doc['status'] ?? 'Menunggu';
            return [
              'Menunggu',
              'Dikemas',
              'Dikirim',
              'Menunggu Pembatalan',
            ].contains(status);
          }).toList();

          var selesaiDocs = filteredDocs
              .where((doc) => doc['status'] == 'Selesai')
              .toList();
          var batalDocs = filteredDocs
              .where((doc) => doc['status'] == 'Dibatalkan')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(berlangsungDocs, "Belum ada pesanan yang berlangsung"),
              _buildList(selesaiDocs, "Belum ada riwayat pesanan selesai"),
              _buildList(batalDocs, "Belum ada pesanan yang dibatalkan"),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET LIST PESANAN ---
  Widget _buildList(List<QueryDocumentSnapshot> docs, String emptyMsg) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade800),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        var t = docs[index];
        Map<String, dynamic> data = t.data() as Map<String, dynamic>;

        String status = data['status'] ?? 'Menunggu';
        String productId = data['productId'] ?? '';
        int qty = data['quantity'] ?? 1;

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Status & ID Pesanan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ID: ${t.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const Divider(color: Colors.white24, height: 25),

                // Info Produk & Harga
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['productName'] ?? 'Barang',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${data['quantity']} Barang",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Total Belanja",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        Text(
                          data['totalPrice'] ?? 'Rp 0',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Info Pembeli (Hanya Penjual) & Alasan Batal
                if (userRole == 'penjual') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pembeli: ${data['buyerName'] ?? 'Anonim'}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (status == 'Menunggu Pembatalan' ||
                    status == 'Dibatalkan') ...[
                  const SizedBox(height: 10),
                  Text(
                    "Alasan Batal: ${data['cancelReason'] ?? '-'}",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Action Buttons
                _buildActionButtons(status, t.id, productId, qty),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIKA TOMBOL BERDASARKAN ROLE & STATUS ---
  Widget _buildActionButtons(
    String status,
    String transId,
    String prodId,
    int qty,
  ) {
    if (userRole == 'pembeli') {
      if (status == 'Menunggu') {
        return _actionRow(
          btnText: "Batalkan Pesanan",
          color: Colors.redAccent,
          onTap: () => _requestCancel(transId),
        );
      } else if (status == 'Dikirim') {
        return _actionRow(
          btnText: "Pesanan Diterima",
          color: Colors.green,
          onTap: () => _completeOrder(transId),
        );
      }
    } else if (userRole == 'penjual') {
      if (status == 'Menunggu') {
        return _actionRow(
          btnText: "Konfirmasi Pesanan",
          color: Colors.blue.shade600,
          onTap: () => _confirmOrder(transId, prodId, qty),
        );
      } else if (status == 'Menunggu Pembatalan') {
        return _actionRow(
          btnText: "Setujui Pembatalan",
          color: Colors.redAccent,
          onTap: () => _approveCancel(transId),
        );
      } else if (status == 'Dikemas') {
        return _actionRow(
          btnText: "Kirim Barang",
          color: Colors.purple.shade600,
          onTap: () => _sendOrder(transId),
        );
      }
    }
    return const SizedBox.shrink(); // Kosong jika tidak ada aksi
  }

  Widget _actionRow({
    required String btnText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            btnText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
