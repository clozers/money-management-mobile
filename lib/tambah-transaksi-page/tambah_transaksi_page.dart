import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class TambahTransaksiPage extends StatefulWidget {
  final String jenis; // 'pengeluaran' atau 'pemasukan'

  const TambahTransaksiPage({
    super.key,
    required this.jenis,
  });

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

  String? _token;
  List<dynamic> _kategoris = [];
  String? _selectedKategoriId;
  bool _isLoading = false;
  bool _isLoadingKategori = true;
  DateTime _selectedDate = DateTime.now();

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
    _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _loadData() async {
    _token = await LocalStorage.getToken();
    if (_token != null) {
      await _loadKategori();
    }
  }

  Future<void> _loadKategori() async {
    setState(() => _isLoadingKategori = true);
    final kategoris = await ApiService.getKategori(_token!);
    print('Kategori loaded: ${kategoris.length} items');
    print('Kategori data: $kategoris');
    setState(() {
      _kategoris = kategoris;
      _isLoadingKategori = false;
      if (_kategoris.isNotEmpty) {
        _selectedKategoriId = _kategoris[0]['id'].toString();
        print('Selected kategori ID: $_selectedKategoriId');
      } else {
        print('No kategori available');
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0E8F6A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.tambahTransaksi(
        _token!,
        widget.jenis,
        _selectedKategoriId!,
        _totalCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
        _tanggalCtrl.text,
        _catatanCtrl.text.isEmpty ? null : _catatanCtrl.text,
      );

      setState(() => _isLoading = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.jenis == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan'} berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true untuk refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan transaksi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _catatanCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPengeluaran = widget.jenis == 'pengeluaran';
    final primaryColor = isPengeluaran
        ? const Color(0xFFE63946) // Soft coral red
        : const Color(0xFF0E8F6A);
    final gradientColors = isPengeluaran
        ? [
            const Color(0xFFE63946),
            const Color(0xFFF77F7F),
            const Color(0xFFFFB4B4),
          ]
        : [
            const Color(0xFF0E8F6A),
            const Color(0xFF14B885),
            const Color(0xFF1AD9A0),
          ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoadingKategori
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header dengan gradient dan back button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Dekorasi lingkaran
                        Positioned(
                          top: -25,
                          right: -25,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  gradientColors[0].withOpacity(0.15),
                                  gradientColors[1].withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 15,
                          left: -20,
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  gradientColors[1].withOpacity(0.12),
                                  gradientColors[0].withOpacity(0.06),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            children: [
                              // Back button
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Title section
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      isPengeluaran
                                          ? Icons.trending_down_rounded
                                          : Icons.trending_up_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isPengeluaran
                                              ? 'Tambah Pengeluaran'
                                              : 'Tambah Pemasukan',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Catat transaksi secara manual',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.95),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Smooth transition
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        gradientColors[2].withOpacity(0.1),
                        Colors.grey[50]!,
                      ],
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Kategori Field
                          Text(
                            'Kategori',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedKategoriId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  color: primaryColor,
                                  size: 22,
                                ),
                              ),
                              hint: Text(
                                'Pilih Kategori',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: primaryColor,
                                size: 28,
                              ),
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              items: _kategoris.map((kategori) {
                                return DropdownMenuItem<String>(
                                  value: kategori['id'].toString(),
                                  child: Text(
                                    kategori['nama_kategori'] ?? 'Kategori',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedKategoriId = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Total Field
                          Text(
                            'Jumlah',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _totalCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.normal,
                                ),
                                prefixIcon: Icon(
                                  Icons.attach_money_rounded,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jumlah tidak boleh kosong';
                                }
                                final num = double.tryParse(
                                    value.replaceAll(RegExp(r'[^\d]'), ''));
                                if (num == null || num <= 0) {
                                  return 'Jumlah harus lebih dari 0';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tanggal Field
                          Text(
                            'Tanggal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _tanggalCtrl,
                              readOnly: true,
                              onTap: _selectDate,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Catatan Field
                          Text(
                            'Catatan (Opsional)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _catatanCtrl,
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[800],
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tambahkan catatan...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 50),
                                  child: Icon(
                                    Icons.note_outlined,
                                    color: primaryColor,
                                    size: 22,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Simpan ${isPengeluaran ? 'Pengeluaran' : 'Pemasukan'}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
