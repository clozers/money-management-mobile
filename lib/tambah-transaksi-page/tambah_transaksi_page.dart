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

// Model untuk item transaksi
class TransaksiItem {
  final String nama;
  final int qty;
  final double harga;

  TransaksiItem({
    required this.nama,
    required this.qty,
    required this.harga,
  });

  double get subtotal => qty * harga;

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'qty': qty,
      'harga': harga,
    };
  }
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

  String? _token;
  List<dynamic> _kategoris = [];
  String? _selectedKategoriId;
  bool _isLoading = false;
  bool _isLoadingKategori = true;
  DateTime _selectedDate = DateTime.now();

  // Items management
  List<TransaksiItem> _items = [];
  bool _useItems = false; // Toggle untuk menggunakan items atau total manual

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
    _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Listen to total controller untuk update jika items berubah
    _totalCtrl.addListener(_updateTotalFromItems);
  }

  void _updateTotalFromItems() {
    // Jika user mengubah total manual setelah items ditambahkan,
    // kita tetap biarkan items ada tapi tidak auto-update total lagi
    // User bisa pilih: pakai total manual atau total dari items
  }

  void _calculateTotalFromItems() {
    if (_items.isNotEmpty) {
      final total = _items.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );
      setState(() {
        _totalCtrl.text = total.toStringAsFixed(0);
        _useItems = true;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      _token = await LocalStorage.getToken();
      if (_token != null) {
        await _loadKategori();
      } else {
        setState(() {
          _isLoadingKategori = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token tidak ditemukan. Silakan login kembali.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoadingKategori = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadKategori() async {
    try {
      setState(() => _isLoadingKategori = true);
      final kategoris = await ApiService.getKategori(_token!);
      print('Kategori loaded: ${kategoris.length} items');
      print('Kategori data: $kategoris');

      setState(() {
        _kategoris = kategoris;
        _isLoadingKategori = false;
        if (_kategoris.isNotEmpty) {
          // Jika belum ada kategori yang dipilih, pilih yang pertama
          if (_selectedKategoriId == null) {
            // Pastikan id ada dan valid
            final firstId = _kategoris[0]['id'];
            if (firstId != null) {
              _selectedKategoriId = firstId.toString();
            }
          }
          print('Selected kategori ID: $_selectedKategoriId');
        } else {
          print('No kategori available');
          _selectedKategoriId = null;
        }
      });
    } catch (e) {
      print('Error loading kategori: $e');
      setState(() {
        _kategoris = [];
        _isLoadingKategori = false;
        _selectedKategoriId = null;
      });

      // Tampilkan error message ke user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showKategoriPicker() async {
    if (_kategoris.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Belum ada kategori. Silakan tambah kategori terlebih dahulu.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Definisikan primaryColor berdasarkan jenis transaksi
    final isPengeluaran = widget.jenis == 'pengeluaran';
    final pickerPrimaryColor =
        isPengeluaran ? const Color(0xFFE63946) : const Color(0xFF0E8F6A);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // List Kategori
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _kategoris.length,
                itemBuilder: (context, index) {
                  final kategori = _kategoris[index];
                  final kategoriId = kategori['id'].toString();
                  final namaKategori = kategori['nama_kategori'] ?? 'Kategori';
                  final isSelected = _selectedKategoriId == kategoriId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? pickerPrimaryColor.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? pickerPrimaryColor : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedKategoriId = kategoriId;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        namaKategori,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? pickerPrimaryColor
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: pickerPrimaryColor,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                _deleteKategori(kategoriId, namaKategori),
                            tooltip: 'Hapus Kategori',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteKategori(String kategoriId, String namaKategori) async {
    // Konfirmasi delete
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Kategori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "$namaKategori"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Delete kategori
    final success = await ApiService.deleteKategori(
      _token!,
      kategoriId,
    );

    // Close loading
    if (mounted) Navigator.pop(context);

    if (success) {
      // Jika kategori yang dihapus adalah kategori yang sedang dipilih, reset selection
      if (_selectedKategoriId == kategoriId) {
        setState(() {
          _selectedKategoriId = null;
        });
      }

      // Refresh list kategori
      await _loadKategori();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus kategori'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showTambahKategoriDialog() async {
    final namaKategoriCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    // Definisikan primaryColor berdasarkan jenis transaksi
    final isPengeluaran = widget.jenis == 'pengeluaran';
    final dialogPrimaryColor =
        isPengeluaran ? const Color(0xFFE63946) : const Color(0xFF0E8F6A);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dialogPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: dialogPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tambah Kategori',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaKategoriCtrl,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                    hintText: 'Contoh: Makanan, Transportasi, dll',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: dialogPrimaryColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.red.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama kategori tidak boleh kosong';
                    }
                    if (value.length < 2) {
                      return 'Nama kategori minimal 2 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final result = await ApiService.tambahKategori(
                        _token!,
                        namaKategoriCtrl.text.trim(),
                      );

                      setDialogState(() => isLoading = false);

                      if (result != null) {
                        // Refresh list kategori
                        await _loadKategori();

                        // Auto-select kategori yang baru ditambahkan
                        if (result['kategori'] != null) {
                          final newKategoriId =
                              result['kategori']['id'].toString();
                          setState(() {
                            _selectedKategoriId = newKategoriId;
                          });
                        } else if (result['id'] != null) {
                          setState(() {
                            _selectedKategoriId = result['id'].toString();
                          });
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Kategori berhasil ditambahkan!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gagal menambahkan kategori'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
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
      // Convert items to JSON format
      List<Map<String, dynamic>>? itemsJson;
      if (_useItems && _items.isNotEmpty) {
        itemsJson = _items.map((item) => item.toJson()).toList();
      }

      final result = await ApiService.tambahTransaksi(
        _token!,
        widget.jenis,
        _selectedKategoriId!,
        _totalCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
        _tanggalCtrl.text,
        _catatanCtrl.text.isEmpty ? null : _catatanCtrl.text,
        _judulCtrl.text.isEmpty ? null : _judulCtrl.text.trim(),
        itemsJson,
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

  void _addItem() {
    _showAddItemDialog();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotalFromItems();
    });
  }

  Future<void> _showAddItemDialog() async {
    final namaCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final hargaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final isPengeluaran = widget.jenis == 'pengeluaran';
    final dialogPrimaryColor =
        isPengeluaran ? const Color(0xFFE63946) : const Color(0xFF0E8F6A);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Minimalist Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tambah Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          letterSpacing: -0.5,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nama Item Field
                  TextFormField(
                    controller: namaCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Item',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      hintText: 'Contoh: Nasi Goreng Special',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: dialogPrimaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama item tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Qty & Harga Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            hintText: '1',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: dialogPrimaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Qty tidak boleh kosong';
                            }
                            final qty = int.tryParse(value);
                            if (qty == null || qty <= 0) {
                              return 'Qty harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: hargaCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Harga',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: dialogPrimaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harga tidak boleh kosong';
                            }
                            final harga = double.tryParse(
                              value.replaceAll(RegExp(r'[^\d]'), ''),
                            );
                            if (harga == null || harga <= 0) {
                              return 'Harga harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons - Clean & Minimal
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final qty = int.parse(qtyCtrl.text);
                                  final harga = double.parse(
                                    hargaCtrl.text.replaceAll(
                                      RegExp(r'[^\d]'),
                                      '',
                                    ),
                                  );

                                  setState(() {
                                    _items.add(
                                      TransaksiItem(
                                        nama: namaCtrl.text.trim(),
                                        qty: qty,
                                        harga: harga,
                                      ),
                                    );
                                    _useItems = true;
                                    _calculateTotalFromItems();
                                  });

                                  Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dialogPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _totalCtrl.removeListener(_updateTotalFromItems);
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
                          // Kategori Field - Clean & Minimal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showKategoriPicker,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kategori',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_outlined,
                                            color: Colors.grey[600],
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _selectedKategoriId != null
                                                  ? _kategoris.firstWhere(
                                                        (k) =>
                                                            k['id']
                                                                .toString() ==
                                                            _selectedKategoriId,
                                                        orElse: () => {},
                                                      )['nama_kategori'] ??
                                                      'Kategori'
                                                  : 'Pilih Kategori',
                                              style: TextStyle(
                                                color:
                                                    _selectedKategoriId != null
                                                        ? Colors.grey[800]
                                                        : Colors.grey[400],
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey[600],
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _selectedKategoriId != null
                                                  ? primaryColor
                                                  : Colors.grey[300]!,
                                              width: _selectedKategoriId != null
                                                  ? 2
                                                  : 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              TextButton.icon(
                                onPressed: _showTambahKategoriDialog,
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Judul Field - Clean & Minimal
                          TextFormField(
                            controller: _judulCtrl,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Judul Transaksi (Opsional)',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              hintText: 'Contoh: Beli smartwatch',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.title,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              errorStyle: TextStyle(color: Colors.red.shade700),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Items Section - Minimalist & Modern (moved here)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header - "Tambahkan item?" dengan tombol "+item"
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tambah pengeluaran per item?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _addItem,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 18,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'item',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Items List - Clean Cards
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ...List.generate(
                                  _items.length,
                                  (index) {
                                    final item = _items[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Item Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.nama,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${item.qty} × ${currencyFormat.format(item.harga)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Subtotal
                                          Text(
                                            currencyFormat
                                                .format(item.subtotal),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Delete Button - Minimal
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _removeItem(index),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],

                              // Total Items - Clean Summary
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(
                                          _items.fold<double>(
                                            0,
                                            (sum, item) => sum + item.subtotal,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Total Field - Clean & Minimal
                          TextFormField(
                            controller: _totalCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Icon(
                                Icons.attach_money_rounded,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
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

                          const SizedBox(height: 32),

                          // Tanggal Field - Clean & Minimal
                          TextFormField(
                            controller: _tanggalCtrl,
                            readOnly: true,
                            onTap: _selectDate,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tanggal',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              hintText: 'Pilih Tanggal',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Catatan Field - Clean & Minimal
                          TextFormField(
                            controller: _catatanCtrl,
                            maxLines: 3,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              labelText: 'Catatan (Opsional)',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                              hintText: 'Tambahkan catatan...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 50),
                                child: Icon(
                                  Icons.note_outlined,
                                  color: Colors.grey[600],
                                  size: 22,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
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
