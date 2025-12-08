import 'dart:convert';
import 'dart:io';
import 'package:easyconnect/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/session_service.dart';

class ApiService {
  // -------------------- HEADERS --------------------
  /// Génère les headers HTTP standardisés pour toutes les requêtes API
  /// Utilise SessionService pour récupérer le token de manière centralisée
  static Map<String, String> headers({bool jsonContent = true}) {
    final token = SessionService.getToken();
    final map = <String, String>{
      'Accept': 'application/json',
      // ⚠️ User-Agent minimal pour contourner Tiger Protect
      // On garde seulement l'essentiel comme curl
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
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
      final requestHeaders = headers();
      final requestBody = jsonEncode({"email": email, "password": password});

      final response = await http
          .post(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: Le serveur ne répond pas dans les 30 secondes',
              );
            },
          );

      return parseResponse(response);
    } on SocketException {
      return {
        "success": false,
        "message":
            "Impossible de se connecter au serveur. Vérifiez votre connexion internet.",
        "errorType": "network",
        "statusCode": null,
      };
    } on HttpException catch (e) {
      return {
        "success": false,
        "message": "Erreur HTTP: ${e.message}",
        "errorType": "http",
        "statusCode": null,
      };
    } on FormatException {
      return {
        "success": false,
        "message": "Erreur de format de réponse du serveur",
        "errorType": "format",
        "statusCode": null,
      };
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('certificate') ||
          errorString.contains('ssl') ||
          errorString.contains('tls') ||
          errorString.contains('handshake')) {
        return {
          "success": false,
          "message":
              "Erreur de certificat SSL. Le serveur peut avoir un problème de certificat.",
          "errorType": "ssl",
          "statusCode": null,
        };
      }

      return {
        "success": false,
        "message": e.toString(),
        "errorType": "unknown",
        "statusCode": null,
      };
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
  ///
  /// IMPORTANT: Vérifie les erreurs HTTP (4xx, 5xx) AVANT de décoder le JSON
  /// pour éviter les exceptions lors du décodage de réponses d'erreur non-JSON
  static Map<String, dynamic> parseResponse(http.Response res) {
    try {
      // 1. Vérifier le status code AVANT tout décodage
      final statusCode = res.statusCode;

      // 2. Gérer le rate limiting (429) avant le parsing
      if (statusCode == 429) {
        return {
          "success": false,
          "message": "Trop de requêtes. Veuillez réessayer plus tard.",
          "statusCode": 429,
        };
      }

      // 3. Gérer les erreurs HTTP (4xx, 5xx) AVANT le décodage JSON
      if (statusCode >= 400) {
        return _handleHttpError(res, statusCode);
      }

      // 4. Pour les succès (2xx), décoder le JSON
      Map<String, dynamic> body = {};

      if (res.body.isNotEmpty) {
        try {
          body = jsonDecode(res.body);
        } catch (e) {
          // Si le décodage échoue même pour un succès, retourner une erreur
          return {
            "success": false,
            "message": "Format de réponse invalide du serveur (JSON invalide)",
            "statusCode": statusCode,
            "rawBody":
                res.body.length > 200
                    ? "${res.body.substring(0, 200)}..."
                    : res.body,
          };
        }
      }

      // 5. Vérifier si la réponse suit le format standardisé
      final hasStandardFormat = body.containsKey('success');

      // 6. Traiter les réponses de succès (2xx)
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
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur de traitement de la réponse: $e",
      };
    }
  }

  /// Gère les erreurs HTTP (4xx, 5xx) en essayant de décoder le JSON
  /// seulement si le body semble être du JSON valide
  static Map<String, dynamic> _handleHttpError(
    http.Response res,
    int statusCode,
  ) {
    String errorMessage = _getDefaultErrorMessage(statusCode);
    Map<String, dynamic>? errors;

    // Essayer de décoder le JSON seulement si le body n'est pas vide
    // et semble être du JSON (commence par { ou [)
    if (res.body.isNotEmpty) {
      final trimmedBody = res.body.trim();
      final isLikelyJson =
          trimmedBody.startsWith('{') ||
          trimmedBody.startsWith('[') ||
          trimmedBody.startsWith('"');

      if (isLikelyJson) {
        try {
          final body = jsonDecode(res.body);

          // Format standardisé
          if (body is Map && body.containsKey('success')) {
            errorMessage = body['message']?.toString() ?? errorMessage;
            errors = body['errors'];
          } else if (body is Map) {
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
                } else if (firstError is String) {
                  errorMessage = firstError;
                }
              }
            }
          }
        } catch (e) {
          // Si le décodage échoue, utiliser le message d'erreur par défaut
          // Ne pas propager l'erreur de décodage
          errorMessage = _getDefaultErrorMessage(statusCode);
        }
      } else {
        // Le body n'est pas du JSON (peut être du HTML, du texte, etc.)
        // Utiliser le message d'erreur par défaut basé sur le status code
        errorMessage = _getDefaultErrorMessage(statusCode);
      }
    }

    return {
      "success": false,
      "message": errorMessage,
      "errors": errors,
      "statusCode": statusCode,
    };
  }

  /// Retourne un message d'erreur par défaut basé sur le code de statut HTTP
  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return "Requête invalide";
      case 401:
        return "Non autorisé. Veuillez vous reconnecter.";
      case 403:
        return "Accès refusé. Vous n'avez pas les permissions nécessaires.";
      case 404:
        return "Ressource non trouvée";
      case 405:
        return "Méthode non autorisée";
      case 422:
        return "Erreur de validation des données";
      case 429:
        return "Trop de requêtes. Veuillez réessayer plus tard.";
      case 500:
        return "Erreur interne du serveur Laravel. Vérifiez les logs du serveur (storage/logs/laravel.log) pour plus de détails.";
      case 502:
        return "Erreur de passerelle. Le serveur est temporairement indisponible.";
      case 503:
        return "Service indisponible. Le serveur est en maintenance ou temporairement inaccessible.";
      case 504:
        return "Timeout de la passerelle. Le serveur ne répond pas.";
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return "Erreur client ($statusCode)";
        } else if (statusCode >= 500) {
          return "Erreur serveur ($statusCode)";
        } else {
          return "Erreur HTTP ($statusCode)";
        }
    }
  }
}
