import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../widgets/custom_app_bar.dart';

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
  final _deskripsiCtrl = TextEditingController();
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
    setState(() {
      _kategoris = kategoris;
      _isLoadingKategori = false;
      if (_kategoris.isNotEmpty) {
        _selectedKategoriId = _kategoris[0]['id'].toString();
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
        _deskripsiCtrl.text.isEmpty ? null : _deskripsiCtrl.text,
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
    _deskripsiCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPengeluaran = widget.jenis == 'pengeluaran';

    return Scaffold(
      appBar: CustomAppBar(
        userName: isPengeluaran ? 'Tambah Pengeluaran' : 'Tambah Pemasukan',
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoadingKategori
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isPengeluaran
                              ? [
                                  Colors.red.withOpacity(0.8),
                                  Colors.red.withOpacity(0.6),
                                ]
                              : [
                                  Colors.green.withOpacity(0.8),
                                  Colors.green.withOpacity(0.6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPengeluaran
                                  ? Icons.trending_down
                                  : Icons.trending_up,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPengeluaran
                                      ? 'Tambah Pengeluaran'
                                      : 'Tambah Pemasukan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Catat transaksi secara manual',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Kategori Field
                    Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKategoriId,
                          isExpanded: true,
                          hint: const Text('Pilih Kategori'),
                          items: _kategoris.map((kategori) {
                            return DropdownMenuItem<String>(
                              value: kategori['id'].toString(),
                              child: Text(kategori['nama_kategori'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedKategoriId = value;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Field
                    Text(
                      'Jumlah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _totalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
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

                    const SizedBox(height: 20),

                    // Tanggal Field
                    Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tanggalCtrl,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: InputDecoration(
                        hintText: 'Pilih Tanggal',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Deskripsi Field
                    Text(
                      'Deskripsi (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan deskripsi...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isPengeluaran ? Colors.red : Color(0xFF0E8F6A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Simpan ${isPengeluaran ? 'Pengeluaran' : 'Pemasukan'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
}
