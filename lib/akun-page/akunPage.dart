import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String? token;
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    token = await LocalStorage.getToken();

    if (token != null) {
      final res = await ApiService.getUser(token!);
      setState(() {
        user = res;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(userName: user?['name']),
      backgroundColor: Colors.grey[100], // 🔥 BIAR SAMA DENGAN HOME
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/pengeluaran');
          }
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Gagal memuat data user"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    // 🔥 GANTI Column → ListView
                    children: [
                      const Text(
                        "Informasi Akun",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _infoCard("Nama", user!['name'] ?? 'Tidak ada'),
                      _infoCard("Email", user!['email'] ?? 'Tidak ada'),
                      _infoCard(
                        "Gaji",
                        user!['gaji_bulanan'] != null
                            ? currencyFormat.format(double.tryParse(
                                    user!['gaji_bulanan'].toString()) ??
                                0)
                            : 'Tidak ada',
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await LocalStorage.logout();
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                          ),
                          child: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black12,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
