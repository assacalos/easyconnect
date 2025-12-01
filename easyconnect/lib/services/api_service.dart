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
      final url = "$baseUrl/login";
      print('🔐 TENTATIVE DE CONNEXION:');
      print('URL: $url');
      print('Email: $email');

      final response = await http
          .post(
            Uri.parse(url),
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

      print('📡 RÉPONSE SERVEUR:');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final result = parseResponse(response);
      print('✅ RÉSULTAT PARSÉ: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ ERREUR API LOGIN:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: $stackTrace');
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: headers(),
      );
      final result = parseResponse(response);
      return result;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // -------------------- USERS --------------------
  static Future<Map<String, dynamic>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'), headers: headers());
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateUserRole(int id, int role) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers(),
      body: jsonEncode({'role': role}),
    );
    return parseResponse(res);
  }

  // -------------------- CLIENTS --------------------
  static Future<Map<String, dynamic>> getClients() async {
    final res = await http.get(
      Uri.parse('$baseUrl/clients'),
      headers: headers(),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> createClient(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateClient(int id, Map data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/clients/$id'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> deleteClient(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/clients/$id'),
      headers: headers(),
    );
    return parseResponse(res);
  }

  // -------------------- QUOTES --------------------
  static Future<Map<String, dynamic>> getQuotes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/quotes'),
      headers: headers(),
    );
    return parseResponse(res);
  }

  static Future<Map<String, dynamic>> createQuote(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/quotes'),
      headers: headers(),
      body: jsonEncode(data),
    );
    return parseResponse(res);
  }

  // -------------------- INVOICES --------------------
  static Future<Map<String, dynamic>> getInvoices() async {
    final res = await http.get(
      Uri.parse('$baseUrl/invoices'),
      headers: headers(),
    );
    return parseResponse(res);
  }

  // -------------------- PARSE --------------------
  /// Parse la réponse HTTP selon le format standardisé de l'API
  /// Format standardisé:
  /// - Succès: {"success": true, "message": "...", "data": {...}}
  /// - Erreur: {"success": false, "message": "...", "errors": {...}}
  static Map<String, dynamic> parseResponse(http.Response res) {
    try {
      Map<String, dynamic> body = {};

      // Gérer le rate limiting (429) avant le parsing
      if (res.statusCode == 429) {
        return {
          "success": false,
          "message": "Trop de requêtes. Veuillez réessayer plus tard.",
          "statusCode": 429,
        };
      }

      if (res.body.isNotEmpty) {
        try {
          body = jsonDecode(res.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Format de réponse invalide du serveur",
          };
        }
      }

      // Vérifier si la réponse suit le format standardisé
      final hasStandardFormat = body.containsKey('success');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Format standardisé détecté
        if (hasStandardFormat) {
          if (body['success'] == true) {
            // Succès: extraire les données de 'data'
            return {
              "success": true,
              "data": body['data'],
              "message": body['message'] ?? "Opération réussie",
            };
          } else {
            // Erreur dans une réponse 2xx (ne devrait pas arriver mais géré)
            return {
              "success": false,
              "message": body['message'] ?? "Erreur inconnue",
              "errors": body['errors'],
            };
          }
        } else {
          // Format non standardisé (rétrocompatibilité)
          if (body.containsKey('data')) {
            return {"success": true, "data": body['data']};
          } else if (body.containsKey('user') && body.containsKey('token')) {
            // Format direct avec user et token (ancien format login)
            return {
              "success": true,
              "data": {"user": body['user'], "token": body['token']},
            };
          } else {
            // Retourner le body tel quel
            return {"success": true, "data": body};
          }
        }
      } else {
        // Gérer les erreurs (4xx, 5xx)
        String errorMessage = "Erreur ${res.statusCode}";
        Map<String, dynamic>? errors;

        // Format standardisé
        if (hasStandardFormat) {
          errorMessage = body['message'] ?? "Erreur ${res.statusCode}";
          errors = body['errors'];
        } else {
          // Format non standardisé (rétrocompatibilité)
          if (body.containsKey('message')) {
            errorMessage = body['message'].toString();
          } else if (body.containsKey('error')) {
            errorMessage = body['error'].toString();
          } else if (body.containsKey('errors')) {
            // Erreurs de validation Laravel
            final validationErrors = body['errors'];
            if (validationErrors is Map) {
              errors = Map<String, dynamic>.from(validationErrors);
              final firstError = validationErrors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              }
            }
          }
        }

        return {
          "success": false,
          "message": errorMessage,
          "errors": errors,
          "statusCode": res.statusCode,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de traitement de la réponse: $e",
      };
    }
  }
}
