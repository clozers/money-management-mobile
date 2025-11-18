import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/loginPage.dart';
import 'auth/registerPage.dart';
import 'home-page/homePage.dart';
import 'akun-page/akunPage.dart';
import 'pengeluaran-page/pengeluaran_page.dart';
import 'scan-struk-page/scan_struk_page.dart';
import 'tambah-transaksi-page/tambah_transaksi_page.dart';
import 'detail-transaksi-page/detail_transaksi_page.dart';
import 'detail-profil-page/detail_profil_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Management App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/akun': (context) => const AccountPage(),
        '/pengeluaran': (context) => const PengeluaranPage(),
        '/scan-struk': (context) => const ScanStrukPage(),
        '/tambah-transaksi': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return TambahTransaksiPage(
            jenis: args?['jenis'] ?? 'pengeluaran',
          );
        },
        '/detail-transaksi': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return DetailTransaksiPage(
            transaksiId: args?['id']?.toString() ?? '',
          );
        },
        '/detail-profil': (context) => const DetailProfilPage(),
      },
    );
  }
}
