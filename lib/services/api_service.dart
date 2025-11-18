import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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

  // 📸 SCAN TRANSAKSI (Upload Struk)
  static Future<Map<String, dynamic>?> scanTransaksi(
      String token, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/scan-transaksi'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add file
      var multipartFile = await http.MultipartFile.fromPath(
        'nota',
        imageFile.path,
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);

      print('Scan transaksi: Uploading file ${imageFile.path}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Scan transaksi response status: ${response.statusCode}');
      print('Scan transaksi response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Scan transaksi error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Scan transaksi exception: $e');
      return null;
    }
  }

  // 📋 GET KATEGORI
  static Future<List<dynamic>> getKategori(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/kategori'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['kategoris'] ?? data['data'] ?? [];
    } else {
      print('Kategori error: ${response.body}');
      return [];
    }
  }

  // ➕ TAMBAH TRANSAKSI MANUAL
  static Future<Map<String, dynamic>?> tambahTransaksi(
    String token,
    String jenis, // 'pengeluaran' atau 'pemasukan'
    String kategoriId,
    String total,
    String? tanggal,
    String? deskripsi,
  ) async {
    final body = jsonEncode({
      'jenis': jenis,
      'kategori_id': kategoriId,
      'total': total,
      'tanggal': tanggal ?? DateTime.now().toIso8601String().split('T')[0],
      'deskripsi': deskripsi ?? '',
    });

    print('Tambah transaksi request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Tambah transaksi response status: ${response.statusCode}');
    print('Tambah transaksi response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Tambah transaksi error: ${response.body}');
      return null;
    }
  }

  // 📄 GET DETAIL TRANSAKSI
  static Future<Map<String, dynamic>?> getDetailTransaksi(
      String token, String transaksiId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transaksi?id=$transaksiId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Detail transaksi response status: ${response.statusCode}');
    print('Detail transaksi response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Handle response format: {"success":true,"pengeluarans":[...]}
      if (data is Map) {
        // Jika ada key 'pengeluarans' (array)
        if (data.containsKey('pengeluarans') && data['pengeluarans'] is List) {
          final pengeluarans = data['pengeluarans'] as List;
          if (pengeluarans.isNotEmpty) {
            // Cari transaksi dengan id yang sesuai
            try {
              final found = pengeluarans.firstWhere(
                (item) => item['id'].toString() == transaksiId,
              );
              return Map<String, dynamic>.from(found);
            } catch (e) {
              // Jika tidak ditemukan, ambil yang pertama
              return Map<String, dynamic>.from(pengeluarans.first);
            }
          }
        }
        // Jika response langsung object transaksi
        return Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        // Jika response langsung array
        try {
          final found = data.firstWhere(
            (item) => item['id'].toString() == transaksiId,
          );
          return Map<String, dynamic>.from(found);
        } catch (e) {
          return Map<String, dynamic>.from(data.first);
        }
      }
      return null;
    } else {
      print(
          'Detail transaksi error: ${response.statusCode} => ${response.body}');
      return null;
    }
  }
}
