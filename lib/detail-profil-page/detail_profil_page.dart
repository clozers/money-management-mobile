import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class DetailProfilPage extends StatefulWidget {
  const DetailProfilPage({super.key});

  @override
  State<DetailProfilPage> createState() => _DetailProfilPageState();
}

class _DetailProfilPageState extends State<DetailProfilPage> {
  String? token;
  Map<String, dynamic>? user;
  bool loading = true;

  final TextEditingController _gajiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _gajiController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    token = await LocalStorage.getToken();

    if (token != null) {
      final res = await ApiService.getUser(token!);
      setState(() {
        user = res;
        if (res != null && res['gaji_bulanan'] != null) {
          _gajiController.text = res['gaji_bulanan'].toString();
        }
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Profil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0E8F6A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data user',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  backgroundColor: const Color(0xFF0E8F6A),
                  color: Colors.white,
                  onRefresh: loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Informasi Akun Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF0E8F6A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF0E8F6A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Informasi Akun',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Nama Card
                          _buildInfoCard(
                            icon: Icons.person_outline,
                            title: 'Nama',
                            value: user!['name'] ?? 'Tidak ada',
                            color: Colors.blue,
                          ),

                          // Email Card
                          _buildInfoCard(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: user!['email'] ?? 'Tidak ada',
                            color: Colors.orange,
                          ),

                          const SizedBox(height: 32),

                          // Gaji Bulanan Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gaji Bulanan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Input Gaji Card
                          Container(
                            padding: const EdgeInsets.all(20),
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
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Gaji Bulanan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Atur gaji bulanan Anda',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _gajiController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Gaji',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                    hintText: 'Masukkan gaji bulanan',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.attach_money_rounded,
                                      color: Color(0xFF0E8F6A),
                                    ),
                                    suffixText: 'Rupiah',
                                    suffixStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF0E8F6A),
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
                                    errorStyle: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Gaji bulanan tidak boleh kosong';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null) {
                                      return 'Masukkan angka yang valid';
                                    }
                                    if (amount < 0) {
                                      return 'Gaji tidak boleh negatif';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        // TODO: Implement API call untuk update gaji
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Fitur update gaji akan segera tersedia'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text(
                                      'Simpan Gaji',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0E8F6A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
