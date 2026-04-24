import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // --- Data Pribadi ---
  late TextEditingController _usernameCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  String? _selectedGender;

  // --- Data Toko (Khusus Penjual) ---
  late bool _isSeller;
  late TextEditingController _storeNameCtrl;
  late TextEditingController _npwpCtrl;
  late TextEditingController _detailAddressCtrl; // Jalan, RT/RW
  late TextEditingController _postalCodeCtrl;

  // State Alamat
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedKecamatan;
  String? _selectedKelurahan;

  // Mock Data Wilayah (Di aplikasi nyata, gunakan API seperti RajaOngkir / API Wilayah Indonesia)
  final Map<String, List<String>> _mockCities = {
    'Banten': [
      'Kota Tangerang',
      'Kab. Tangerang',
      'Kota Cilegon',
      'Kota Serang',
    ],
    'DKI Jakarta': [
      'Jakarta Selatan',
      'Jakarta Barat',
      'Jakarta Pusat',
      'Jakarta Timur',
    ],
    'Jawa Barat': ['Kota Bandung', 'Kota Bekasi', 'Kota Bogor', 'Kab. Bogor'],
  };

  // State Metode Pembayaran
  bool _isGopay = false;
  bool _isOvo = false;
  bool _isCod = false;

  // File QRIS
  File? _qrisGopayFile;
  File? _qrisOvoFile;
  String? _qrisGopayUrl;
  String? _qrisOvoUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Data Pribadi
    _usernameCtrl = TextEditingController(
      text: widget.userData['username'] ?? '',
    );
    _fullNameCtrl = TextEditingController(
      text: widget.userData['fullName'] ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.userData['phone'] ?? '');
    _dobCtrl = TextEditingController(text: widget.userData['dob'] ?? '');
    _selectedGender = widget.userData['gender'];

    // Inisialisasi Data Toko
    _isSeller = widget.userData['role'] == 'penjual';
    _storeNameCtrl = TextEditingController(
      text: widget.userData['storeName'] ?? '',
    );
    _npwpCtrl = TextEditingController(text: widget.userData['npwp'] ?? '');
    _detailAddressCtrl = TextEditingController(
      text: widget.userData['addressDetail'] ?? '',
    );
    _postalCodeCtrl = TextEditingController(
      text: widget.userData['postalCode'] ?? '',
    );

    _selectedProvince = widget.userData['province'];
    _selectedCity = widget.userData['city'];
    _selectedKecamatan = widget.userData['kecamatan'];
    _selectedKelurahan = widget.userData['kelurahan'];

    _isGopay = widget.userData['isGopay'] ?? false;
    _isOvo = widget.userData['isOvo'] ?? false;
    _isCod = widget.userData['isCod'] ?? false;

    _qrisGopayUrl = widget.userData['qrisGopayUrl'];
    _qrisOvoUrl = widget.userData['qrisOvoUrl'];
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _storeNameCtrl.dispose();
    _npwpCtrl.dispose();
    _detailAddressCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  // Pick Image
  Future<void> _pickImage(bool isGopay) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        if (isGopay) {
          _qrisGopayFile = File(pickedFile.path);
        } else {
          _qrisOvoFile = File(pickedFile.path);
        }
      });
    }
  }

  // Upload to Firebase Storage
  Future<String?> _uploadQRIS(File file, String pathName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'qris_merchants/$pathName.jpg',
      );
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi QRIS jika aktif
    if (_isSeller) {
      if (_isGopay &&
          _qrisGopayFile == null &&
          (_qrisGopayUrl == null || _qrisGopayUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harap upload QRIS GoPay!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (_isOvo &&
          _qrisOvoFile == null &&
          (_qrisOvoUrl == null || _qrisOvoUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harap upload QRIS OVO!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        String? newGopayUrl = _qrisGopayUrl;
        String? newOvoUrl = _qrisOvoUrl;

        // Proses Upload Gambar Jika Ada yang Baru
        if (_qrisGopayFile != null) {
          newGopayUrl = await _uploadQRIS(_qrisGopayFile!, '${user.uid}_gopay');
        }
        if (_qrisOvoFile != null) {
          newOvoUrl = await _uploadQRIS(_qrisOvoFile!, '${user.uid}_ovo');
        }

        // Data Dasar
        Map<String, dynamic> updateData = {
          'username': _usernameCtrl.text.trim(),
          'fullName': _fullNameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'dob': _dobCtrl.text.trim(),
          'gender': _selectedGender,
          'email': user.email,
          'updatedAt': Timestamp.now(),
        };

        // Tambah Data Toko jika penjual
        if (_isSeller) {
          updateData.addAll({
            'storeName': _storeNameCtrl.text.trim(),
            'npwp': _npwpCtrl.text.trim(),
            'province': _selectedProvince,
            'city': _selectedCity,
            'kecamatan': _selectedKecamatan,
            'kelurahan': _selectedKelurahan,
            'postalCode': _postalCodeCtrl.text.trim(),
            'addressDetail': _detailAddressCtrl.text.trim(),
            // displayLocation ini yang akan ditarik oleh Homepage & Product Detail
            'displayLocation': _selectedCity ?? 'Belum diatur',
            'isGopay': _isGopay,
            'isOvo': _isOvo,
            'isCod': _isCod,
            'qrisGopayUrl': newGopayUrl,
            'qrisOvoUrl': newOvoUrl,
          });
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil berhasil diperbarui! 🎉"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menyimpan: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "UBAH PROFIL",
          style: TextStyle(color: Colors.orangeAccent),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Data Pribadi",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white24, height: 30),

              _buildLabel("Username"),
              _buildTextField(
                _usernameCtrl,
                Icons.person_outline,
                "Masukkan username",
                true,
              ),

              _buildLabel("Nama Lengkap"),
              _buildTextField(
                _fullNameCtrl,
                Icons.badge_outlined,
                "Masukkan nama sesuai KTP",
                true,
              ),

              _buildLabel("No. Telepon / WhatsApp"),
              _buildTextField(
                _phoneCtrl,
                Icons.phone_android,
                "Contoh: 08123456789",
                true,
                isNumber: true,
              ),

              // --- TAMBAHAN JENIS KELAMIN ---
              _buildLabel("Jenis Kelamin"),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle(Icons.wc),
                items: ['Laki-laki', 'Perempuan']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                validator: (value) =>
                    value == null ? "Pilih jenis kelamin" : null,
              ),

              // --- TAMBAHAN TANGGAL LAHIR ---
              _buildLabel("Tanggal Lahir"),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true, // Supaya keyboard tidak muncul
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle(Icons.calendar_today).copyWith(
                  hintText: "Pilih tanggal lahir",
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.orangeAccent,
                            onPrimary: Colors.black,
                            surface: Color(0xFF1E1E1E),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      // Format: DD-MM-YYYY
                      _dobCtrl.text =
                          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return "Wajib diisi";
                  return null;
                },
              ),

              // --- SECTION TOKO ---
              if (_isSeller) ...[
                const SizedBox(height: 30),
                const Text(
                  "Informasi Toko",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24, height: 30),

                _buildLabel("Nama Toko"),
                _buildTextField(
                  _storeNameCtrl,
                  Icons.storefront,
                  "Masukkan nama toko",
                  true,
                ),

                _buildLabel("NPWP (Opsional)"),
                _buildTextField(
                  _npwpCtrl,
                  Icons.credit_card,
                  "Nomor NPWP",
                  false,
                  isNumber: true,
                ),

                const SizedBox(height: 20),
                const Text(
                  "Alamat Toko",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                _buildLabel("Provinsi"),
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle(Icons.map),
                  items: _mockCities.keys
                      .map(
                        (prov) =>
                            DropdownMenuItem(value: prov, child: Text(prov)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProvince = val;
                      _selectedCity = null; // Reset kota saat provinsi berubah
                    });
                  },
                  validator: (value) => value == null ? "Pilih provinsi" : null,
                ),

                _buildLabel("Kota / Kabupaten (Tampil di Detail Produk)"),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputStyle(Icons.location_city),
                  items: _selectedProvince == null
                      ? []
                      : _mockCities[_selectedProvince!]!
                            .map(
                              (city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ),
                            )
                            .toList(),
                  onChanged: (val) => setState(() => _selectedCity = val),
                  validator: (value) =>
                      value == null ? "Pilih kota/kabupaten" : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Kecamatan"),
                          DropdownButtonFormField<String>(
                            value: _selectedKecamatan,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(Icons.place),
                            items: ['Kec. A', 'Kec. B']
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ),
                                )
                                .toList(), // Ganti pakai API
                            onChanged: (val) =>
                                setState(() => _selectedKecamatan = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Desa/Kelurahan"),
                          DropdownButtonFormField<String>(
                            value: _selectedKelurahan,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputStyle(Icons.holiday_village),
                            items: ['Desa X', 'Desa Y']
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(), // Ganti pakai API
                            onChanged: (val) =>
                                setState(() => _selectedKelurahan = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildLabel("Kode Pos"),
                _buildTextField(
                  _postalCodeCtrl,
                  Icons.markunread_mailbox,
                  "Kode Pos",
                  true,
                  isNumber: true,
                ),

                _buildLabel("Alamat Lengkap (Jalan, RT/RW)"),
                TextFormField(
                  controller: _detailAddressCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputStyle(
                    Icons.home,
                  ).copyWith(hintText: "Contoh: Jl. Sudirman No 10, RT 01/02"),
                  validator: (value) =>
                      value!.isEmpty ? "Isi detail alamat" : null,
                ),

                const SizedBox(height: 30),
                const Text(
                  "Metode Pembayaran",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Aktifkan minimal satu metode pembayaran.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),

                _buildPaymentSwitch(
                  "Bayar di Tempat (COD)",
                  _isCod,
                  (val) => setState(() => _isCod = val),
                ),

                _buildPaymentSwitch(
                  "GoPay",
                  _isGopay,
                  (val) => setState(() => _isGopay = val),
                ),
                if (_isGopay) _buildQRISUploader("Upload QRIS GoPay", true),

                _buildPaymentSwitch(
                  "OVO",
                  _isOvo,
                  (val) => setState(() => _isOvo = val),
                ),
                if (_isOvo) _buildQRISUploader("Upload QRIS OVO", false),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
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
                          "SIMPAN PROFIL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String hint,
    bool isRequired, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputStyle(icon).copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "Wajib diisi";
        }
        return null;
      },
    );
  }

  InputDecoration _inputStyle(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.orangeAccent),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
    );
  }

  Widget _buildPaymentSwitch(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      activeColor: Colors.orangeAccent,
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildQRISUploader(String title, bool isGopay) {
    File? currentFile = isGopay ? _qrisGopayFile : _qrisOvoFile;
    String? currentUrl = isGopay ? _qrisGopayUrl : _qrisOvoUrl;

    return GestureDetector(
      onTap: () => _pickImage(isGopay),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: currentFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  currentFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : (currentUrl != null && currentUrl.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  currentUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.orangeAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white70)),
                ],
              ),
      ),
    );
  }
}
