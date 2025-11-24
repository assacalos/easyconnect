import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';

class ClientService {
  final storage = GetStorage();

  Future<List<Client>> getClients({
    int? status,
    bool? isPending = false,
  }) async {
    try {
      // Si status est null, on veut TOUS les statuts
      // On fait plusieurs appels (un pour chaque statut) et on combine les résultats
      if (status == null) {
        final allClients = <Client>[];

        // Récupérer les clients pour chaque statut (0, 1, 2)
        for (int stat = 0; stat <= 2; stat++) {
          try {
            final clients = await _fetchClientsByStatus(stat, isPending);
            allClients.addAll(clients);
          } catch (e) {
            // Continue avec les autres statuts même si un échoue
          }
        }

        return allClients;
      }

      // Si un statut spécifique est demandé, faire un seul appel
      return await _fetchClientsByStatus(status, isPending);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  Future<List<Client>> _fetchClientsByStatus(
    int status,
    bool? isPending,
  ) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      queryParams['status'] = status.toString();
      if (isPending == true) queryParams['pending'] = 'true';
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/clients-list$queryString';
      // Vérifier que le token existe
      if (token == null || token.toString().isEmpty) {
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous reconnecter.',
        );
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          List<dynamic> data = [];

          // Gérer différents formats de réponse de l'API
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map) {
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null) {
                if (responseData['data']['data'] is List) {
                  data = responseData['data']['data'];
                }
              }
            } else if (responseData['clients'] != null) {
              if (responseData['clients'] is List) {
                data = responseData['clients'];
              }
            }
          }
          if (data.isEmpty &&
              responseData is Map &&
              responseData.containsKey('success') &&
              responseData['success'] == true) {
            return [];
          }

          // Filtrer par statut (double vérification côté client)
          if (data.isNotEmpty) {
            data =
                data.where((item) {
                  if (item is Map) {
                    final itemStatus = item['status'];
                    int? parsedStatus;
                    if (itemStatus is String) {
                      parsedStatus = int.tryParse(itemStatus);
                    } else if (itemStatus is int) {
                      parsedStatus = itemStatus;
                    }
                    return parsedStatus == status;
                  }
                  return true;
                }).toList();
          }

          final clients = data.map((json) => Client.fromJson(json)).toList();
          return clients;
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
          'Accès refusé (403). Vous n\'avez pas les permissions pour accéder aux clients. Vérifiez vos droits d\'accès.',
        );
      }

      // Si c'est une erreur 401, elle a déjà été gérée
      if (response.statusCode == 401) {
        throw Exception('Session expirée');
      }

      throw Exception(
        'Erreur lors de la récupération des clients: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }

      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  Future<Client> createClient(Client client) async {
    try {
      final token = storage.read('token');
      final userId = storage.read('userId');

      var clientData = client.toJson();
      clientData['user_id'] = userId;
      clientData['status'] = 0; // Toujours en attente à la création
      final response = await http.post(
        Uri.parse('$baseUrl/clients-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(clientData),
      );
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return Client.fromJson(responseData['data']);
        }
        // Si pas de data mais status 201, le client a été créé
        // On retourne le client original
        return client;
      }
      // Essayer d'extraire le message d'erreur de la réponse
      String errorMessage = 'Erreur lors de la création du client';
      try {
        final errorData = json.decode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        // Si le parsing échoue, utiliser le message par défaut
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  Future<Client> updateClient(Client client) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/clients-update/${client.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(client.toJson()),
      );

      if (response.statusCode == 200) {
        return Client.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du client');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du client');
    }
  }

  Future<bool> approveClient(int clientId) async {
    try {
      final token = storage.read('token');

      final url = '$baseUrl/clients-validate/$clientId';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectClient(int clientId, String comment) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/clients-reject/$clientId';
      final body = json.encode({'commentaire': comment});
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      // Log spécial pour les erreurs 500
      if (response.statusCode == 500) {}

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/clients-delete/$clientId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/clients/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
