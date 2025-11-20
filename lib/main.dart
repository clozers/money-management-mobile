import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash-screen/splash_screen.dart';
import 'auth/loginPage.dart';
import 'auth/registerPage.dart';
import 'home-page/homePage.dart';
import 'akun-page/akunPage.dart';
import 'pengeluaran-page/pengeluaran_page.dart';
import 'scan-struk-page/scan_struk_page.dart';
import 'tambah-transaksi-page/tambah_transaksi_page.dart';
import 'detail-transaksi-page/detail_transaksi_page.dart';
import 'edit-transaksi-page/edit_transaksi_page.dart';
import 'detail-profil-page/detail_profil_page.dart';
import 'analisis-page/analisis_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpendKu',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
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
        '/edit-transaksi': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return EditTransaksiPage(
            transaksiId: args?['id']?.toString() ?? '',
            detail: args?['detail'] as Map<String, dynamic>?,
          );
        },
        '/detail-profil': (context) => const DetailProfilPage(),
        '/analisis': (context) => const AnalisisPage(),
      },
    );
  }
}
