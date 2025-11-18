import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
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
  double totalGaji = 0;
  List<dynamic> transaksi = [];
  bool isLoading = true;

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

    if (token == null) return;

    // 🔥 PANGGIL DUA API SEKALIGUS
    final home = await ApiService.getHome(token!);
    final pengeluaran = await ApiService.getTransaksi(token!);

    setState(() {
      // Data dari API /home
      totalBulan = double.tryParse(
              home?['total_pengeluaran_bulan_ini'].toString() ?? "0") ??
          0;
      totalMinggu = double.tryParse(
              home?['total_pengeluaran_minggu_ini'].toString() ?? "0") ??
          0;
      totalGaji = double.tryParse(home?['sisa_gaji'].toString() ?? "0") ?? 0;
      userName = home?['nama_user'] ?? userName;

      // Data dari API /pengeluaran
      transaksi = pengeluaran; // 🔥 AKHIRNYA MUNCUL

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(userName: userName),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ================= Gaji Card =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Gaji Bulan Ini",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(totalGaji),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= Pengeluaran Card =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Pengeluaran Bulan Ini",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(totalBulan),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Minggu ini: ${currencyFormat.format(totalMinggu)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= Transaksi Minggu Ini =================
                  const Text("Transaksi Minggu Ini",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  if (transaksi.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text("Belum ada transaksi.")),
                    )
                  else
                    ...transaksi.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long,
                              color: Color(0xFF0E8F6A)),
                          title: Text(item['kategori']['nama_kategori'] ??
                              'Tanpa kategori'),
                          subtitle: Text(item['tanggal'] ?? ''),
                          trailing: Text(
                            currencyFormat.format(
                              double.tryParse(item['total'].toString()) ?? 0,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/tambah'),
        backgroundColor: const Color(0xFF0E8F6A),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
