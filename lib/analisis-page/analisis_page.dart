import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';

class AnalisisPage extends StatefulWidget {
  const AnalisisPage({super.key});

  @override
  State<AnalisisPage> createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  String? token;
  List<dynamic> transaksi = [];
  bool isLoading = true;
  int? touchedPieIndex; // Untuk menyimpan index pie chart yang diklik

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    loadData();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
  }

  Future<void> loadData() async {
    token = await LocalStorage.getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final pengeluaran = await ApiService.getTransaksi(token!);
    setState(() {
      transaksi = pengeluaran;
      isLoading = false;
    });
  }

  // Hitung data per kategori
  Map<String, double> _calculateKategoriData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    Map<String, double> kategoriMap = {};

    for (var item in transaksi) {
      try {
        String dateStr = item['tanggal'] ?? item['created_at'] ?? '';
        if (dateStr.isNotEmpty) {
          final transaksiDate = DateTime.parse(dateStr.split('T')[0]);
          if (transaksiDate
              .isAfter(startOfMonth.subtract(const Duration(days: 1)))) {
            final kategoriNama =
                item['kategori']?['nama_kategori'] ?? 'Lainnya';
            final total = double.tryParse(item['total'].toString()) ?? 0;
            kategoriMap[kategoriNama] =
                (kategoriMap[kategoriNama] ?? 0) + total;
          }
        }
      } catch (e) {
        // Skip jika error
      }
    }

    return kategoriMap;
  }

  // Hitung trend bulanan (6 bulan terakhir)
  List<Map<String, dynamic>> _calculateMonthlyTrend() {
    final now = DateTime.now();
    List<Map<String, dynamic>> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);

      double total = 0;
      for (var item in transaksi) {
        try {
          String dateStr = item['tanggal'] ?? item['created_at'] ?? '';
          if (dateStr.isNotEmpty) {
            final transaksiDate = DateTime.parse(dateStr.split('T')[0]);
            if (transaksiDate
                    .isAfter(monthDate.subtract(const Duration(days: 1))) &&
                transaksiDate.isBefore(nextMonth)) {
              total += double.tryParse(item['total'].toString()) ?? 0;
            }
          }
        } catch (e) {
          // Skip jika error
        }
      }

      // List nama bulan dalam bahasa Indonesia
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      monthlyData.add({
        'month': monthNames[monthDate.month - 1],
        'total': total,
      });
    }

    return monthlyData;
  }

  // Hitung statistik overview
  Map<String, dynamic> _calculateOverview() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    double totalBulanIni = 0;
    int jumlahTransaksi = 0;
    double rataRataHari = 0;
    String kategoriTerbesar = 'Tidak ada';
    double kategoriTerbesarTotal = 0;

    Map<String, double> kategoriMap = {};

    for (var item in transaksi) {
      try {
        String dateStr = item['tanggal'] ?? item['created_at'] ?? '';
        if (dateStr.isNotEmpty) {
          final transaksiDate = DateTime.parse(dateStr.split('T')[0]);
          if (transaksiDate
              .isAfter(startOfMonth.subtract(const Duration(days: 1)))) {
            final total = double.tryParse(item['total'].toString()) ?? 0;
            totalBulanIni += total;
            jumlahTransaksi++;

            final kategoriNama =
                item['kategori']?['nama_kategori'] ?? 'Lainnya';
            kategoriMap[kategoriNama] =
                (kategoriMap[kategoriNama] ?? 0) + total;

            if (kategoriMap[kategoriNama]! > kategoriTerbesarTotal) {
              kategoriTerbesarTotal = kategoriMap[kategoriNama]!;
              kategoriTerbesar = kategoriNama;
            }
          }
        }
      } catch (e) {
        // Skip jika error
      }
    }

    final hariIni = now.day;
    rataRataHari = hariIni > 0 ? totalBulanIni / hariIni : 0;

    return {
      'totalBulanIni': totalBulanIni,
      'jumlahTransaksi': jumlahTransaksi,
      'rataRataHari': rataRataHari,
      'kategoriTerbesar': kategoriTerbesar,
      'kategoriTerbesarTotal': kategoriTerbesarTotal,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Analisis Pengeluaran',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0E8F6A),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final kategoriData = _calculateKategoriData();
    final monthlyTrend = _calculateMonthlyTrend();
    final overview = _calculateOverview();

    // Siapkan data untuk pie chart
    final pieData = kategoriData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Ambil top 5 untuk bar chart
    final top5Kategori = pieData.take(5).toList();

    // Warna untuk kategori
    final List<Color> colors = [
      const Color(0xFF0E8F6A),
      const Color(0xFF14B885),
      const Color(0xFF1AD9A0),
      const Color(0xFFE63946),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA07A),
      const Color(0xFFFFD700),
      const Color(0xFF9370DB),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analisis Pengeluaran',
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
      body: RefreshIndicator(
        backgroundColor: const Color(0xFF0E8F6A),
        color: Colors.white,
        onRefresh: loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview Cards
              _buildOverviewSection(overview),

              const SizedBox(height: 24),

              // Pie Chart - Distribusi Kategori
              if (kategoriData.isNotEmpty) ...[
                _buildSectionTitle('Distribusi Pengeluaran per Kategori'),
                const SizedBox(height: 16),
                _buildPieChart(pieData, colors),
                const SizedBox(height: 24),
              ],

              // Bar Chart - Top 5 Kategori
              if (top5Kategori.isNotEmpty) ...[
                _buildSectionTitle('Top 5 Kategori Pengeluaran'),
                const SizedBox(height: 16),
                _buildBarChart(top5Kategori, colors),
                const SizedBox(height: 24),
              ],

              // Line Chart - Trend Bulanan
              if (monthlyTrend.isNotEmpty) ...[
                _buildSectionTitle('Trend Pengeluaran (6 Bulan Terakhir)'),
                const SizedBox(height: 16),
                _buildLineChart(monthlyTrend),
                const SizedBox(height: 24),
              ],

              // List Kategori Detail
              if (pieData.isNotEmpty) ...[
                _buildSectionTitle('Detail per Kategori'),
                const SizedBox(height: 16),
                _buildKategoriList(
                    pieData, colors, overview['totalBulanIni'] as double),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Bulan Ini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Pengeluaran',
                currencyFormat.format(overview['totalBulanIni']),
                Icons.account_balance_wallet,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Jumlah Transaksi',
                '${overview['jumlahTransaksi']}',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Rata-rata per Hari',
                currencyFormat.format(overview['rataRataHari']),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Kategori Terbesar',
                (overview['kategoriTerbesar'] as String).length > 12
                    ? '${(overview['kategoriTerbesar'] as String).substring(0, 12)}...'
                    : overview['kategoriTerbesar'],
                Icons.category,
                const Color(0xFF0E8F6A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPieChart(
      List<MapEntry<String, double>> data, List<Color> colors) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = data.fold<double>(0, (sum, entry) => sum + entry.value);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: SizedBox(
                height: 180,
                child: Center(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: data.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final percentage = (item.value / total * 100);
                        final isTouched = index == touchedPieIndex;

                        return PieChartSectionData(
                          value: item.value,
                          title: isTouched
                              ? '${percentage.toStringAsFixed(1)}%'
                              : '',
                          radius: isTouched ? 28 : 25,
                          color: colors[index % colors.length],
                          titleStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedPieIndex = null;
                              return;
                            }
                            touchedPieIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final percentage = (item.value / total * 100);
                final isTouched = index == touchedPieIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isTouched
                          ? colors[index % colors.length].withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isTouched ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTouched
                                ? colors[index % colors.length]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      List<MapEntry<String, double>> data, List<Color> colors) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipBgColor: Colors.grey[800]!,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    final kategori = data[value.toInt()].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        kategori.length > 6
                            ? '${kategori.substring(0, 6)}...'
                            : kategori,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  // Format singkat untuk nilai besar
                  String formatted;
                  if (value >= 1000000) {
                    formatted = '${(value / 1000000).toStringAsFixed(1)}JT';
                  } else if (value >= 1000) {
                    formatted = '${(value / 1000).toStringAsFixed(0)}RB';
                  } else {
                    formatted = value.toStringAsFixed(0);
                  }
                  return Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  );
                },
                reservedSize: 45,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  color: colors[index % colors.length],
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue =
        data.map((e) => e['total'] as double).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Text(
                      data[value.toInt()]['month'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  // Format singkat untuk nilai besar
                  String formatted;
                  if (value >= 1000000) {
                    formatted = '${(value / 1000000).toStringAsFixed(1)}JT';
                  } else if (value >= 1000) {
                    formatted = '${(value / 1000).toStringAsFixed(0)}RB';
                  } else {
                    formatted = value.toStringAsFixed(0);
                  }
                  return Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  );
                },
                reservedSize: 45,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(
                    entry.key.toDouble(), entry.value['total'] as double);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF0E8F6A),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF0E8F6A),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0E8F6A).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriList(
      List<MapEntry<String, double>> data, List<Color> colors, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final percentage = (item.value / total * 100);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: index < data.length - 1 ? 1 : 0,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% dari total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(item.value),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
