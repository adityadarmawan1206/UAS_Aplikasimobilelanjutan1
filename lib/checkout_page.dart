import 'dart:async';
import 'package:app/transaction_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// TODO: Pastikan kamu meng-import halaman TransactionPage kamu di sini
// import 'package:nama_project_kamu/transaction_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;

  const CheckoutPage({super.key, required this.checkoutItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Controller Alamat
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _subDistrictController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Status Alamat (apakah sudah diisi atau belum)
  bool _isAddressFilled = false;

  // State Pengiriman
  String _selectedShipping = 'Reguler';
  final Map<String, int> _shippingRates = {
    'Kargo': 35000,
    'Reguler': 15000,
    'Ambil di toko': 0,
    'Sameday': 25000,
    'Instant': 40000,
  };

  int get _shippingCost => _shippingRates[_selectedShipping] ?? 0;

  // State Pembayaran
  String _selectedPayment = 'Transfer Bank';
  final List<String> _paymentMethods = ['Transfer Bank', 'OVO', 'GoPay', 'COD'];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int _parsePrice(String priceStr) {
    String cleanStr = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanStr) ?? 0;
  }

  int _calculateSubtotal() {
    int subtotal = 0;
    for (var item in widget.checkoutItems) {
      int qty = item['quantity'] ?? 1;
      int price = _parsePrice(item['price'] ?? '0');
      subtotal += (price * qty);
    }
    return subtotal;
  }

  // Menampilkan Bottom Sheet untuk Form Alamat
  void _showAddressForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ubah Alamat Pengiriman",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(_nameController, "Nama Penerima"),
                  _buildTextField(
                    _phoneController,
                    "No Telp",
                    type: TextInputType.phone,
                  ),
                  _buildTextField(_provinceController, "Provinsi"),
                  _buildTextField(_cityController, "Kabupaten/Kota"),
                  _buildTextField(_districtController, "Kecamatan"),
                  _buildTextField(_subDistrictController, "Kelurahan"),
                  _buildTextField(
                    _addressController,
                    "Alamat Lengkap (Cth: Jl. Merdeka No. 1)",
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isAddressFilled = true);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "SIMPAN ALAMAT",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) => value!.isEmpty ? "Harap diisi" : null,
      ),
    );
  }

  // --- FUNGSI ANIMASI & NAVIGASI KHUSUS COD ---
  void _showCODSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animasi Bouncy Icon
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Icon(
                        Icons.local_shipping, // Logo Truk Pengiriman
                        color: Colors.orangeAccent,
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Pesanan Diproses",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Mohon tunggu, kamu akan diarahkan ke halaman pesanan...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.orangeAccent),
              ],
            ),
          ),
        );
      },
    );

    // Tunggu 5 Detik, lalu arahkan ke halaman TransactionPage
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog

        // Pindah ke halaman TransactionPage
        // Pastikan kelas TransactionPage sudah diimport di atas
        // Navigator.pushAndRemoveUntil digunakan agar user tidak bisa 'back' ke halaman checkout ini lagi
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            // Ganti pemanggilan TransactionPage() sesuai dengan parameter di kodemu (misal jika ada inisial tab)
            builder: (context) => const TransactionPage(),
          ),
          (route) => route.isFirst,
        );
      }
    });
  }

  Future<void> _processOrder() async {
    if (!_isAddressFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon isi alamat pengiriman terlebih dahulu!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      _showAddressForm();
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    String buyerId = user?.uid ?? 'unknown';

    Map<String, dynamic> shippingAddress = {
      'namaPenerima': _nameController.text.trim(),
      'noTelp': _phoneController.text.trim(),
      'provinsi': _provinceController.text.trim(),
      'kota': _cityController.text.trim(),
      'kecamatan': _districtController.text.trim(),
      'kelurahan': _subDistrictController.text.trim(),
      'alamatLengkap': _addressController.text.trim(),
    };

    try {
      DateTime now = DateTime.now();
      DateTime deadline = now.add(const Duration(hours: 24));
      String orderGroupId = "ORD-${now.millisecondsSinceEpoch}";

      for (var item in widget.checkoutItems) {
        int qty = item['quantity'] ?? 1;
        int priceInt = _parsePrice(item['price'] ?? '0');
        int total = (priceInt * qty) + _shippingCost;

        await FirebaseFirestore.instance.collection('transactions').add({
          'orderGroupId': orderGroupId,
          'buyerId': buyerId,
          'productId': item['productId'],
          'productName': item['productName'],
          'quantity': qty,
          'totalPrice': total,
          'status':
              'Menunggu Pembayaran', // Bisa kamu ganti "Diproses" khusus COD di Firestore jika mau
          'paymentMethod': _selectedPayment,
          'shippingMethod': _selectedShipping,
          'shippingAddress': shippingAddress,
          'createdAt': Timestamp.fromDate(now),
          'paymentDeadline': Timestamp.fromDate(deadline),
        });

        if (item.containsKey('cartId')) {
          await FirebaseFirestore.instance
              .collection('carts')
              .doc(item['cartId'])
              .delete();
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // --- LOGIKA NAVIGASI PEMBAYARAN ---
        if (_selectedPayment == 'OVO' || _selectedPayment == 'GoPay') {
          int grandTotal = _calculateSubtotal() + _shippingCost;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionPaymentPage(
                paymentMethod: _selectedPayment,
                totalAmount: grandTotal,
                orderGroupId: orderGroupId,
                deadline: deadline,
              ),
            ),
          );
        } else if (_selectedPayment == 'COD') {
          // Panggil animasi sukses 5 detik untuk COD
          _showCODSuccessDialog();
        } else {
          // Untuk Transfer Bank / Lainnya
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pesanan berhasil dibuat! 🚀"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int subtotal = _calculateSubtotal();
    int grandTotal = subtotal + _shippingCost;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Bagian Alamat
            InkWell(
              onTap: _showAddressForm,
              child: Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.orangeAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isAddressFilled
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Alamat Pengiriman",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_nameController.text} | ${_phoneController.text}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_addressController.text}, ${_subDistrictController.text}, ${_districtController.text}, ${_cityController.text}, ${_provinceController.text}",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "Pilih Alamat Pengiriman",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            // Garis pembatas estetik
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent,
                    Colors.blueAccent,
                    Colors.orangeAccent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Daftar Pesanan
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.storefront, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Pesanan Kamu",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  ...widget.checkoutItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['imageUrl'] ?? '',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['price'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "x${item['quantity']}",
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Opsi Pengiriman (Dropdown)
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Opsi Pengiriman",
                    style: TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF2A2A2A),
                        value: _selectedShipping,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        alignment: Alignment.centerRight,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        items: _shippingRates.keys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text("$key (Rp ${_shippingRates[key]})"),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedShipping = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Metode Pembayaran (Dropdown)
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Metode Pembayaran",
                    style: TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF2A2A2A),
                        value: _selectedPayment,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        alignment: Alignment.centerRight,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        items: _paymentMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPayment = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. Rincian Pembayaran
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rincian Pembayaran",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal Produk",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        "Rp $subtotal",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal Pengiriman",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        "Rp $_shippingCost",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 6. Bar Bawah
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    "Rp $grandTotal",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _processOrder,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Buat Pesanan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PLACEHOLDER HALAMAN PAYMENT UNTUK OVO/GOPAY
// ==========================================
class TransactionPaymentPage extends StatelessWidget {
  final String paymentMethod;
  final int totalAmount;
  final String orderGroupId;
  final DateTime deadline;

  const TransactionPaymentPage({
    super.key,
    required this.paymentMethod,
    required this.totalAmount,
    required this.orderGroupId,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "Pembayaran $paymentMethod",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Tagihan",
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            Text(
              "Rp $totalAmount",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.qr_code_2, size: 200, color: Colors.grey[900]),
            ),
            const SizedBox(height: 20),
            Text(
              "Harap bayar sebelum:",
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              "${deadline.day}/${deadline.month}/${deadline.year} ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text(
                "SAYA SUDAH BAYAR",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CATATAN:
// Jangan lupa pindahkan class TransactionPaymentPage ke file terpisahnya sendiri
// (transaction_payment_page.dart) jika kamu ingin rapi, lalu import ke file checkout ini!
