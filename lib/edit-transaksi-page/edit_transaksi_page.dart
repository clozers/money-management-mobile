import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class EditTransaksiPage extends StatefulWidget {
  final String transaksiId;
  final Map<String, dynamic>? detail;

  const EditTransaksiPage({
    super.key,
    required this.transaksiId,
    this.detail,
  });

  @override
  State<EditTransaksiPage> createState() => _EditTransaksiPageState();
}

class _EditTransaksiPageState extends State<EditTransaksiPage> {
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
  bool _isLoadingDetail = true;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _detail;

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _token = await LocalStorage.getToken();
      if (_token != null) {
        // Load detail jika belum ada
        if (widget.detail == null) {
          _detail =
              await ApiService.getDetailTransaksi(_token!, widget.transaksiId);
        } else {
          _detail = widget.detail;
        }

        await _loadKategori();

        // Set data ke form
        if (_detail != null) {
          _judulCtrl.text = _detail!['judul'] ?? '';
          _totalCtrl.text = _detail!['total']?.toString() ?? '';
          _catatanCtrl.text = _detail!['catatan'] ?? '';

          // Set tanggal
          if (_detail!['tanggal'] != null) {
            try {
              _selectedDate = DateTime.parse(_detail!['tanggal']);
              _tanggalCtrl.text =
                  DateFormat('yyyy-MM-dd').format(_selectedDate);
            } catch (e) {
              _tanggalCtrl.text =
                  DateFormat('yyyy-MM-dd').format(DateTime.now());
            }
          } else {
            _tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
          }

          // Set kategori
          if (_detail!['kategori'] != null &&
              _detail!['kategori']['id'] != null) {
            _selectedKategoriId = _detail!['kategori']['id'].toString();
          }
        }

        setState(() {
          _isLoadingDetail = false;
        });
      } else {
        setState(() {
          _isLoadingDetail = false;
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
        _isLoadingDetail = false;
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
        // Jika belum ada kategori yang dipilih dan ada kategori tersedia, pilih yang pertama
        if (_selectedKategoriId == null && _kategoris.isNotEmpty) {
          final firstId = _kategoris[0]['id'];
          if (firstId != null) {
            _selectedKategoriId = firstId.toString();
          }
        }
        print('Selected kategori ID: $_selectedKategoriId');
      });
    } catch (e) {
      print('Error loading kategori: $e');
      setState(() {
        _kategoris = [];
        _isLoadingKategori = false;
        _selectedKategoriId = null;
      });

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
              primary: const Color(0xFF0E8F6A),
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
      final result = await ApiService.updateTransaksi(
        _token!,
        widget.transaksiId,
        _selectedKategoriId!,
        _totalCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
        _tanggalCtrl.text,
        _catatanCtrl.text.isEmpty ? null : _catatanCtrl.text,
        _judulCtrl.text.isEmpty ? null : _judulCtrl.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true untuk refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupdate transaksi'),
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
    _judulCtrl.dispose();
    _totalCtrl.dispose();
    _catatanCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
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

    final pickerPrimaryColor = const Color(0xFF0E8F6A);

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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await ApiService.deleteKategori(
      _token!,
      kategoriId,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      if (_selectedKategoriId == kategoriId) {
        setState(() {
          _selectedKategoriId = null;
        });
      }

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

    final dialogPrimaryColor = const Color(0xFF0E8F6A);

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
                        await _loadKategori();

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

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0E8F6A);
    final gradientColors = [
      const Color(0xFF0E8F6A),
      const Color(0xFF14B885),
      const Color(0xFF1AD9A0),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoadingDetail || _isLoadingKategori
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            children: [
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
                                    child: const Icon(
                                      Icons.edit_outlined,
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
                                        const Text(
                                          'Edit Transaksi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Ubah data transaksi',
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                              fontSize: 15,
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
                          TextFormField(
                            controller: _totalCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 15,
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
                                        const Text(
                                          'Simpan Perubahan',
                                          style: TextStyle(
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
