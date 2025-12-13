import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? token;
  String? userName;
  double totalBulan = 0;
  double totalMinggu = 0;
  double totalGaji = 0; // Sisa gaji
  double gajiBulanan = 0; // Gaji bulanan
  int tanggalGajian = 1; // Default tanggal 1
  List<dynamic> transaksi = [];
  bool isLoading = true;
  bool hasResetThisMonth = false; // State untuk sembunyikan banner

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    token = await LocalStorage.getToken();
    userName = await LocalStorage.getName();
    final lastReset = await LocalStorage.getLastReset();
    final currentMonthKey = "${DateTime.now().month}-${DateTime.now().year}";
    
    if (lastReset == currentMonthKey) {
      if (mounted) setState(() => hasResetThisMonth = true);
    }

    if (token == null) return;

    // 🔥 PANGGIL TIGA API SEKALIGUS
    final home = await ApiService.getHome(token!);
    final pengeluaran = await ApiService.getTransaksi(token!);
    final user = await ApiService.getUser(token!);

    // Hitung pengeluaran minggu ini dari transaksi (7 hari terakhir)
    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 7));

    double pengeluaranMingguIni = 0;
    for (var item in pengeluaran) {
      try {
        String dateStr = item['tanggal'] ?? item['created_at'] ?? '';
        if (dateStr.isNotEmpty) {
          final transaksiDate = DateTime.parse(dateStr.split('T')[0]);
          final transaksiDateOnly = DateTime(
              transaksiDate.year, transaksiDate.month, transaksiDate.day);
          final startDateOnly =
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final nowDateOnly = DateTime(now.year, now.month, now.day);

          // Jika transaksi dalam 7 hari terakhir
          if (transaksiDateOnly
                  .isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
              transaksiDateOnly
                  .isBefore(nowDateOnly.add(const Duration(days: 1)))) {
            final total = double.tryParse(item['total'].toString()) ?? 0;
            pengeluaranMingguIni += total;
          }
        }
      } catch (e) {
        // Skip jika error parsing tanggal
      }
    }

    setState(() {
      // Data dari API /home
      totalBulan = double.tryParse(
              home?['total_pengeluaran_bulan_ini'].toString() ?? "0") ??
          0;
      totalMinggu = pengeluaranMingguIni; // Hitung dari transaksi per minggu
      userName = home?['nama_user'] ?? userName;

      // Data dari API /user
      gajiBulanan =
          double.tryParse(user?['gaji_bulanan'].toString() ?? "0") ?? 0;
      tanggalGajian = int.tryParse(user?['tanggal_gajian'].toString() ?? "1") ?? 1;
      totalGaji = double.tryParse(user?['sisa_gaji'].toString() ?? "0") ?? 0;

      // Data dari API /pengeluaran
      // Sort dari terbaru ke terlama berdasarkan created_at atau tanggal
      pengeluaran.sort((a, b) {
        // Coba pakai created_at dulu, kalau tidak ada pakai tanggal
        String dateA = a['created_at'] ?? a['tanggal'] ?? '';
        String dateB = b['created_at'] ?? b['tanggal'] ?? '';

        if (dateA.isEmpty || dateB.isEmpty) return 0;

        try {
          final dateTimeA = DateTime.parse(dateA);
          final dateTimeB = DateTime.parse(dateB);
          // Sort descending (terbaru dulu)
          return dateTimeB.compareTo(dateTimeA);
        } catch (e) {
          return 0;
        }
      });

      transaksi = pengeluaran; // 🔥 AKHIRNYA MUNCUL

      isLoading = false;
    });
  }

  Future<void> _resetGaji() async {
    if (token == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Saldo?'),
        content: Text(
            'Saldo akan di-reset menjadi ${currencyFormat.format(gajiBulanan)}.\n\nPastikan Anda benar-benar sudah gajian untuk bulan baru!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E8F6A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Reset!'),
          ),
        ],
      ),
    );

    if (!confirm) return;

    setState(() => isLoading = true);
    final result = await ApiService.resetGaji(token!);
    setState(() => isLoading = false);

    if (result != null && result['success'] == true) {
      // Simpan status bahwa bulan ini sudah reset
      final currentMonthKey = "${DateTime.now().month}-${DateTime.now().year}";
      await LocalStorage.setResetDone(currentMonthKey);
      
      setState(() {
        hasResetThisMonth = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hore! Saldo berhasil di-reset. Selamat gajian! 🥳'),
          backgroundColor: Colors.green,
        ),
      );
      loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mereset saldo. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sisaGaji = totalGaji;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SpendKu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0E8F6A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xFF0E8F6A),
      body: isLoading
          ? Container(
              color: Color(0xFF0E8F6A),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadData,
              color: Colors.white,
              backgroundColor: Color(0xFF0E8F6A),
              child: Container(
                color: Color(0xFF0E8F6A),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ================= Header Gradient Section =================
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0E8F6A),
                            Color(0xFF14B885),
                            Color(0xFF1AD9A0),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Decorative circles dengan gradient yang smooth
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
                                    Color(0xFF1AD9A0).withOpacity(0.15),
                                    Color(0xFF14B885).withOpacity(0.08),
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
                                    Color(0xFF14B885).withOpacity(0.12),
                                    Color(0xFF0E8F6A).withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 35,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFF1AD9A0).withOpacity(0.1),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Sisa Gaji',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.95),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            currencyFormat.format(sisaGaji),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -1,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.celebration,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Masih tersisa untuk kebutuhanmu',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.95),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.25),
                                            Colors.white.withOpacity(0.15),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 36,
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

                    // ================= Background Transition =================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ================= Payday Banner (Conditional) =================
                          // Tampilkan jika tanggal hari ini >= tanggalGajian
                          // DAN belum reset bulan ini
                          if (!hasResetThisMonth && 
                              DateTime.now().day >= tanggalGajian && 
                              DateTime.now().day <= tanggalGajian + 7) 
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFF0E8F6A).withOpacity(0.1),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0E8F6A).withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Animated-like Icon
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0E8F6A), Color(0xFF14B885)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0E8F6A).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.calendar_month_rounded,
                                          color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 16),

                                    // Text Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Text(
                                                'Periode Baru!',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Icon(Icons.stars_rounded,
                                                  color: Colors.orange, size: 16),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Saatnya tutup buku dan reset budget',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _resetGaji,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAFBF4),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0xFF0E8F6A)
                                                    .withOpacity(0.3)),
                                          ),
                                          child: const Text(
                                            'Reset',
                                            style: TextStyle(
                                              color: Color(0xFF0E8F6A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                          const SizedBox(height: 10),

                          // ================= Stats Cards =================
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      context,
                                      'Gaji Bulan Ini',
                                      currencyFormat.format(gajiBulanan),
                                      Icons.trending_up,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _statCard(
                                      context,
                                      'Pengeluaran',
                                      currencyFormat.format(totalBulan),
                                      Icons.trending_down,
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ================= Pengeluaran Minggu Ini Card =================
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pengeluaran Minggu Ini',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormat.format(totalMinggu),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ================= Motivational Section =================
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF0E8F6A).withOpacity(0.08),
                                    const Color(0xFF14B885).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      const Color(0xFF0E8F6A).withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF0E8F6A),
                                          const Color(0xFF14B885),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.insights,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kelola Keuangan dengan Bijak',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Setiap transaksi yang kamu catat adalah langkah menuju kebebasan finansial',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ================= Quick Actions =================
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catat Transaksi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih cara mencatat transaksi: scan struk otomatis atau input manual',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        icon: Icons.camera_alt,
                                        label: 'Scan Struk',
                                        color: const Color(0xFF0E8F6A),
                                        onTap: () => Navigator.pushNamed(
                                            context, '/scan-struk'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickActionButton(
                                        context,
                                        icon: Icons.add,
                                        label: 'Tambah Manual',
                                        color: Colors.orange.shade600,
                                        onTap: () async {
                                          final result =
                                              await Navigator.pushNamed(
                                            context,
                                            '/tambah-transaksi',
                                            arguments: {'jenis': 'pengeluaran'},
                                          );
                                          if (result == true) {
                                            loadData();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Analisis Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/analisis');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF0E8F6A),
                                      const Color(0xFF14B885),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0E8F6A)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.analytics_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Analisis Pengeluaran',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lihat analisis detail pengeluaran Anda',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Text(
                                  'Transaksi Terbaru',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/pengeluaran'),
                                  child: const Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      color: Color(0xFF0E8F6A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (transaksi.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada transaksi',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mulai catat pengeluaran Anda',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...transaksi.take(5).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () async {
                                          final result =
                                              await Navigator.pushNamed(
                                            context,
                                            '/detail-transaksi',
                                            arguments: {'id': item['id']},
                                          );
                                          // Refresh data jika transaksi dihapus
                                          if (result == true) {
                                            loadData();
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(0xFF0E8F6A),
                                                    const Color(0xFF14B885),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF0E8F6A)
                                                            .withOpacity(0.15),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.receipt_long_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Judul transaksi (jika ada)
                                                  if (item['judul'] != null &&
                                                      item['judul']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      item['judul'].toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                        letterSpacing: -0.1,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  else
                                                    Text(
                                                      item['kategori']?[
                                                              'nama_kategori'] ??
                                                          'Tanpa kategori',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                        letterSpacing: -0.1,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 13,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        item['tanggal'] ?? '',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[500],
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              currencyFormat.format(
                                                double.tryParse(item['total']
                                                        .toString()) ??
                                                    0,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Colors.red,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1)
            Navigator.pushReplacementNamed(context, '/pengeluaran');
          if (index == 2) Navigator.pushReplacementNamed(context, '/akun');
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
