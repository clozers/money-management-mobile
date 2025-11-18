import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://brightfuture.my.id/api';
  // Ganti dengan domain atau IP API kamu (pastikan HTTPS aktif)

  // 🔐 LOGIN
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Login error: ${response.body}');
      return null;
    }
  }

  // 📝 REGISTER
  static Future<Map<String, dynamic>?> register(String name, String email,
      String password, String passwordConfirmation, String gajiBulanan) async {
    // Convert gaji to number if possible
    final gajiValue = double.tryParse(gajiBulanan) ?? 0;

    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'gaji': gajiValue,
    });

    print('Register request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/registrasi'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('Register response status: ${response.statusCode}');
    print('Register response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Register error: ${response.body}');
      return null;
    }
  }

  // 🏠 HOME PAGE
  static Future<Map<String, dynamic>?> getHome(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/home'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Home error: ${response.statusCode} => ${response.body}');
      return null;
    }
  }

  // 👤 USER LOGIN DETAIL
  static Future<Map<String, dynamic>?> getUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('User error: ${response.statusCode} => ${response.body}');
      return null;
    }
  }

  // 🧾 GET LIST TRANSAKSI
  static Future<List<dynamic>> getTransaksi(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transaksi'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['pengeluarans'] ?? [];
    } else {
      print('Transaksi error: ${response.body}');
      return [];
    }
  }
}
