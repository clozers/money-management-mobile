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
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/tambah');
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
