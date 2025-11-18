import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../widgets/custom_bottom_nav.dart';
import 'package:intl/intl.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  List<dynamic> pengeluarans = [];
  String? token;
  bool loading = true;

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    token = await LocalStorage.getToken();

    if (token != null) {
      final data = await ApiService.getTransaksi(token!);

      // Sort dari terbaru ke terlama berdasarkan created_at atau tanggal
      data.sort((a, b) {
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

      setState(() {
        pengeluarans = data;
        loading = false;
      });
    }
  }

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tambah Transaksi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Scan Nota Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF0E8F6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.scanner,
                    color: Color(0xFF0E8F6A),
                  ),
                ),
                title: const Text(
                  'Scan Nota',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle:
                    const Text('Upload foto struk untuk deteksi otomatis'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan-struk');
                },
              ),
              const SizedBox(height: 8),
              // Tambah Manual - Pengeluaran
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_down,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  'Tambah Pengeluaran',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Catat pengeluaran secara manual'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    '/tambah-transaksi',
                    arguments: {'jenis': 'pengeluaran'},
                  );
                  if (result == true) {
                    loadData(); // Refresh data
                  }
                },
              ),
              const SizedBox(height: 8),
              // Tambah Manual - Pemasukan
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  'Tambah Pemasukan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Catat pemasukan secara manual'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    '/tambah-transaksi',
                    arguments: {'jenis': 'pemasukan'},
                  );
                  if (result == true) {
                    loadData(); // Refresh data
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Hitung total pengeluaran
  double getTotalPengeluaran() {
    return pengeluarans.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item['total'].toString()) ?? 0),
    );
  }

  // Format tanggal untuk display
  String formatTanggal(String? tanggal) {
    if (tanggal == null) return '-';
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPengeluaran = getTotalPengeluaran();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFF0E8F6A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 2) Navigator.pushReplacementNamed(context, '/akun');
        },
      ),
      backgroundColor: Colors.grey[50],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              backgroundColor: const Color(0xFF0E8F6A),
              color: Colors.white,
              onRefresh: loadData,
              child: CustomScrollView(
                slivers: [
                  // Header dengan statistik
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0E8F6A),
                            const Color(0xFF14B885),
                            const Color(0xFF1AD9A0),
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
                          // Dekorasi lingkaran dengan gradient yang smooth
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
                                    const Color(0xFF1AD9A0).withOpacity(0.15),
                                    const Color(0xFF14B885).withOpacity(0.08),
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
                                    const Color(0xFF14B885).withOpacity(0.12),
                                    const Color(0xFF0E8F6A).withOpacity(0.06),
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
                                    const Color(0xFF1AD9A0).withOpacity(0.1),
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Total Pengeluaran',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currencyFormat
                                                .format(totalPengeluaran),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -1,
                                              height: 1.1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.trending_down,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${pengeluarans.length} transaksi',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 13,
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
                                        Icons.receipt_long,
                                        color: Colors.white,
                                        size: 32,
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

                  // List transaksi
                  if (pengeluarans.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Belum ada pengeluaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mulai catat pengeluaran Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _showAddTransactionDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Pengeluaran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E8F6A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = pengeluarans[index];
                            final kategoriNama = item['kategori']
                                    ?['nama_kategori'] ??
                                'Tidak ada kategori';
                            final tanggal = formatTanggal(item['tanggal']);
                            final total =
                                double.tryParse(item['total'].toString()) ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/detail-transaksi',
                                      arguments: {'id': item['id']},
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          // Icon kategori dengan gradient
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  const Color(0xFF0E8F6A)
                                                      .withOpacity(0.15),
                                                  const Color(0xFF14B885)
                                                      .withOpacity(0.15),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFF0E8F6A)
                                                    .withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.receipt_long_rounded,
                                              color: Color(0xFF0E8F6A),
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Info transaksi
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  kategoriNama,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today,
                                                            size: 12,
                                                            color: Colors
                                                                .grey[700],
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            tanggal,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[700],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
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
                                          const SizedBox(width: 12),
                                          // Total dengan arrow
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  currencyFormat.format(total),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.grey[600],
                                                  size: 12,
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
                          },
                          childCount: pengeluarans.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: const Color(0xFF0E8F6A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
