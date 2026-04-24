import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- IMPORT HALAMAN KAMU DI SINI ---
import 'home_tab.dart';
import 'profile_tab.dart';
import 'transaction_page.dart'; // <-- Halaman Pesanan
import 'product_management_page.dart'; // <-- Import halaman Kelola Stock di sini

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _userRole = 'pembeli'; // Default
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Mengambil role user dari Firestore untuk dioper ke HomeTab dan menyusun menu
  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'pembeli';
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }

    // --- MENYUSUN DAFTAR HALAMAN & MENU SECARA DINAMIS ---

    // 1. Menu wajib (Home & Pesanan) yang ada untuk semua role
    List<Widget> pages = [
      HomeTab(userRole: _userRole),
      const TransactionPage(),
    ];

    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Pesanan',
      ),
    ];

    // 2. Jika role = penjual, tambahkan halaman & menu "Kelola Stock" di tengah
    if (_userRole == 'penjual') {
      pages.add(const ProductManagementPage()); // Mengarah ke Kelola Stock
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory), // Ikon disesuaikan jadi inventory
          label: 'Kelola Stock',
        ),
      );
    }

    // 3. Profil selalu ditambahkan paling akhir agar posisinya di pojok kanan
    pages.add(const ProfileTab());
    navItems.add(
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    );

    // Pengaman: Jika index melebihi jumlah halaman (misal saat logout/pindah akun), kembalikan ke 0
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Pastikan icon tidak bergeser
        items: navItems,
      ),
    );
  }
}
