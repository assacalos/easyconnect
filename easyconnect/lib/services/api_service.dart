import 'dart:convert';
import 'package:easyconnect/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ApiService {
  // -------------------- HEADERS --------------------
  static Map<String, String> headers({bool jsonContent = true}) {
    final token = GetStorage().read<String?>('token');
    final map = <String, String>{'Accept': 'application/json'};
    if (token != null) map['Authorization'] = 'Bearer $token';
    if (jsonContent) map['Content-Type'] = 'application/json';
    return map;
  }

  // -------------------- AUTH --------------------
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: headers(),
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(
            const Duration(seconds: 30), // Timeout plus long
            onTimeout: () {
              throw Exception(
                'Timeout: Le serveur ne répond pas dans les 30 secondes',
              );
            },
          );
      final result = _parse(response);
      return result;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: headers(),
      );
      final result = _parse(response);
      return result;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // -------------------- USERS --------------------
  static Future<Map<String, dynamic>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'), headers: headers());
    return _parse(res);
  }

  static Future<Map<String, dynamic>> updateUserRole(int id, int role) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers(),
      body: jsonEncode({'role': role}),
    );
    return _parse(res);
  }

  // -------------------- CLIENTS --------------------
  static Future<Map<String, dynamic>> getClients() async {
    final res = await http.get(
      Uri.parse('$baseUrl/clients'),
      headers: headers(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> createClient(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> updateClient(int id, Map data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/clients/$id'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> deleteClient(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/clients/$id'),
      headers: headers(),
    );
    return _parse(res);
  }

  // -------------------- QUOTES --------------------
  static Future<Map<String, dynamic>> getQuotes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/quotes'),
      headers: headers(),
    );
    return _parse(res);
  }

  static Future<Map<String, dynamic>> createQuote(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/quotes'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return _parse(res);
  }

  // -------------------- INVOICES --------------------
  static Future<Map<String, dynamic>> getInvoices() async {
    final res = await http.get(
      Uri.parse('$baseUrl/invoices'),
      headers: headers(),
    );
    return _parse(res);
  }

  // -------------------- PRIVATE PARSE --------------------
  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"success": true, "data": body};
      } else {
        return {
          "success": false,
          "message": body["message"] ?? "Erreur ${res.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Invalid response format"};
    }
  }
}
