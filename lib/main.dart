import 'package:flutter/material.dart';
import 'auth/loginPage.dart';
import 'auth/registerPage.dart';
import 'home-page/homePage.dart';
import 'akun-page/akunPage.dart';
import 'pengeluaran-page/pengeluaran_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Management App',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/akun': (context) => const AccountPage(),
        '/pengeluaran': (context) => const PengeluaranPage(),

      },
    );
  }
}
