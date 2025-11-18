import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../widgets/custom_app_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(userName: "Pengeluaran"),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          if (index == 2) Navigator.pushReplacementNamed(context, '/akun');
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: pengeluarans.isEmpty
                  ? const Center(child: Text("Belum ada transaksi"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pengeluarans.length,
                      itemBuilder: (context, index) {
                        final item = pengeluarans[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 4,
                                color: Colors.black12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long,
                                color: Colors.teal),

                            // kategori.nama_kategori
                            title: Text(
                              item['kategori']?['nama_kategori'] ??
                                  'Tidak ada kategori',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),

                            // tanggal
                            subtitle: Text("Tanggal: ${item['tanggal']}"),

                            // total
                            trailing: Text(
                              currencyFormat.format(item['total']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detail-transaksi',
                                arguments: {'id': item['id']},
                              );
                            },
                          ),
                        );
                      },
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
