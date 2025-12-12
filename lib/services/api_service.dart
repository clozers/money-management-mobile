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

  // 💰 UPDATE GAJI BULANAN
  static Future<Map<String, dynamic>?> updateGaji(
    String token,
    double gajiBulanan,
  ) async {
    final body = jsonEncode({
      'gaji_bulanan': gajiBulanan,
    });

    print('Update gaji request body: $body');

    final response = await http.put(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Update gaji response status: ${response.statusCode}');
    print('Update gaji response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Update gaji error: ${response.body}');
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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kategori'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Kategori response status: ${response.statusCode}');
      print('Kategori response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Handle berbagai format response
          if (data is List) {
            // Jika response langsung array
            return List<dynamic>.from(data);
          } else if (data is Map<String, dynamic>) {
            // Jika response adalah object dengan key
            if (data.containsKey('kategoris')) {
              final kategoris = data['kategoris'];
              if (kategoris is List) {
                return List<dynamic>.from(kategoris);
              }
            }
            if (data.containsKey('data')) {
              final dataList = data['data'];
              if (dataList is List) {
                return List<dynamic>.from(dataList);
              }
            }
            if (data.containsKey('kategori')) {
              final kategori = data['kategori'];
              if (kategori is List) {
                return List<dynamic>.from(kategori);
              }
            }
          }

          print(
              'Kategori: Format response tidak dikenali. Data type: ${data.runtimeType}');
          return [];
        } catch (e) {
          print('Kategori: Error parsing response: $e');
          return [];
        }
      } else {
        print('Kategori error: ${response.statusCode} => ${response.body}');
        return [];
      }
    } catch (e) {
      print('Kategori exception: $e');
      return [];
    }
  }

  // ➕ TAMBAH KATEGORI
  static Future<Map<String, dynamic>?> tambahKategori(
      String token, String namaKategori) async {
    final body = jsonEncode({
      'nama_kategori': namaKategori,
    });

    print('Tambah kategori request body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/kategori'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Tambah kategori response status: ${response.statusCode}');
    print('Tambah kategori response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Tambah kategori error: ${response.body}');
      return null;
    }
  }

  // 🗑️ DELETE KATEGORI
  static Future<bool> deleteKategori(String token, String kategoriId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/kategori/$kategoriId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete kategori response status: ${response.statusCode}');
      print('Delete kategori response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Delete kategori error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete kategori exception: $e');
      return false;
    }
  }

  // ➕ TAMBAH TRANSAKSI MANUAL
  static Future<Map<String, dynamic>?> tambahTransaksi(
    String token,
    String jenis, // 'pengeluaran' atau 'pemasukan'
    String kategoriId,
    String total,
    String? tanggal,
    String? catatan,
    String? judul,
    List<Map<String, dynamic>>? items,
  ) async {
    // Convert total to number
    final totalValue =
        double.tryParse(total.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    // Format tanggal
    final tanggalValue =
        tanggal ?? DateTime.now().toIso8601String().split('T')[0];

    // Build body sesuai format API: kategori_id, tanggal, total, catatan, judul, items
    final bodyMap = <String, dynamic>{
      'kategori_id': int.tryParse(kategoriId) ?? 0,
      'tanggal': tanggalValue,
      'total': totalValue,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      if (judul != null && judul.isNotEmpty) 'judul': judul,
      if (items != null && items.isNotEmpty) 'items': items,
    };

    final body = jsonEncode(bodyMap);

    print('Tambah transaksi request body: $body');
    print('Jenis transaksi: $jenis');

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

  // 🗑️ DELETE TRANSAKSI
  static Future<bool> deleteTransaksi(String token, String transaksiId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transaksi/$transaksiId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete transaksi response status: ${response.statusCode}');
      print('Delete transaksi response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Delete transaksi error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete transaksi exception: $e');
      return false;
    }
  }

  // ✏️ UPDATE TRANSAKSI
  static Future<Map<String, dynamic>?> updateTransaksi(
    String token,
    String transaksiId,
    String kategoriId,
    String total,
    String? tanggal,
    String? catatan,
    String? judul,
    List<Map<String, dynamic>>? items,
  ) async {
    // Convert total to number
    final totalValue =
        double.tryParse(total.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    // Format tanggal
    final tanggalValue =
        tanggal ?? DateTime.now().toIso8601String().split('T')[0];

    // Build body sesuai format API: kategori_id, tanggal, total, catatan, judul, items
    final bodyMap = <String, dynamic>{
      'kategori_id': int.tryParse(kategoriId) ?? 0,
      'tanggal': tanggalValue,
      'total': totalValue,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      if (judul != null && judul.isNotEmpty) 'judul': judul,
      if (items != null && items.isNotEmpty) 'items': items,
    };

    final body = jsonEncode(bodyMap);

    print('Update transaksi request body: $body');

    final response = await http.put(
      Uri.parse('$baseUrl/transaksi/$transaksiId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('Update transaksi response status: ${response.statusCode}');
    print('Update transaksi response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Update transaksi error: ${response.body}');
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
