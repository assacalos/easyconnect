import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/constant.dart';

class CommercialDashboardService {
  final storage = GetStorage();

  // Récupérer les entités en attente
  Future<Map<String, int>> getPendingEntities() async {
    try {
      final token = storage.read('token');
      int pendingClients = 0;
      int pendingDevis = 0;
      int pendingBordereaux = 0;
      int pendingBonCommandes = 0;

      // Récupérer les clients en attente
      try {
        final clientsResponse = await http.get(
          Uri.parse('$baseUrl/api/clients-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (clientsResponse.statusCode == 200) {
          final clientsData = json.decode(clientsResponse.body);
          print('📊 Clients data: $clientsData');
          // Gérer différents formats de réponse
          List clientsList = [];
          if (clientsData is List) {
            clientsList = clientsData;
          } else if (clientsData is Map && clientsData['data'] != null) {
            if (clientsData['data'] is List) {
              clientsList = clientsData['data'];
            }
          }
          pendingClients =
              clientsList
                  .where(
                    (client) =>
                        client['status'] == 0 || client['status'] == null,
                  )
                  .length; // 0 = en attente pour clients
          print('📊 Pending clients: $pendingClients');
        }
      } catch (e) {
        print('Erreur clients: $e');
      }

      // Récupérer les devis en attente
      try {
        final devisResponse = await http.get(
          Uri.parse('$baseUrl/api/devis-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (devisResponse.statusCode == 200) {
          final devisData = json.decode(devisResponse.body);
          print('📊 Devis data: $devisData');
          // Gérer différents formats de réponse
          List devisList = [];
          if (devisData is List) {
            devisList = devisData;
          } else if (devisData is Map && devisData['data'] != null) {
            if (devisData['data'] is List) {
              devisList = devisData['data'];
            }
          }
          pendingDevis =
              devisList
                  .where((devis) => devis['status'] == 1)
                  .length; // 1 = en attente
          print('📊 Pending devis: $pendingDevis');
        }
      } catch (e) {
        print('Erreur devis: $e');
      }

      // Récupérer les bordereaux en attente
      try {
        final bordereauxResponse = await http.get(
          Uri.parse('$baseUrl/api/bordereaux-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (bordereauxResponse.statusCode == 200) {
          final bordereauxData = json.decode(bordereauxResponse.body);
          print('📊 Bordereaux data: $bordereauxData');
          // Gérer différents formats de réponse
          List bordereauxList = [];
          if (bordereauxData is List) {
            bordereauxList = bordereauxData;
          } else if (bordereauxData is Map && bordereauxData['data'] != null) {
            if (bordereauxData['data'] is List) {
              bordereauxList = bordereauxData['data'];
            }
          }
          pendingBordereaux =
              bordereauxList
                  .where((bordereau) => bordereau['status'] == 1)
                  .length; // 1 = en attente
          print('📊 Pending bordereaux: $pendingBordereaux');
        }
      } catch (e) {
        print('Erreur bordereaux: $e');
      }

      // Récupérer les bons de commande en attente
      try {
        final bonCommandesResponse = await http.get(
          Uri.parse('$baseUrl/api/bons-de-commande-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (bonCommandesResponse.statusCode == 200) {
          final bonCommandesData = json.decode(bonCommandesResponse.body);
          if (bonCommandesData['data'] != null &&
              bonCommandesData['data']['data'] is List) {
            pendingBonCommandes =
                bonCommandesData['data']['data']
                    .where((bon) => bon['status'] == 1)
                    .length; // 1 = en attente
          }
        }
      } catch (e) {
        print('Erreur bons de commande: $e');
      }

      return {
        'clients': pendingClients,
        'devis': pendingDevis,
        'bordereaux': pendingBordereaux,
        'bon_commandes': pendingBonCommandes,
      };
    } catch (e) {
      print('Erreur: $e');
      return {'clients': 0, 'devis': 0, 'bordereaux': 0, 'bon_commandes': 0};
    }
  }

  // Récupérer les entités validées
  Future<Map<String, int>> getValidatedEntities() async {
    try {
      final token = storage.read('token');
      int validatedClients = 0;
      int validatedDevis = 0;
      int validatedBordereaux = 0;
      int validatedBonCommandes = 0;

      // Récupérer les clients validés
      try {
        final clientsResponse = await http.get(
          Uri.parse('$baseUrl/api/clients-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (clientsResponse.statusCode == 200) {
          final clientsData = json.decode(clientsResponse.body);
          if (clientsData is List) {
            validatedClients =
                clientsData.where((client) => client['status'] == 1).length;
          }
        }
      } catch (e) {
        print('Erreur clients validés: $e');
      }

      // Récupérer les devis validés
      try {
        final devisResponse = await http.get(
          Uri.parse('$baseUrl/api/devis-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (devisResponse.statusCode == 200) {
          final devisData = json.decode(devisResponse.body);
          if (devisData is List) {
            validatedDevis =
                devisData
                    .where((devis) => devis['status'] == 2)
                    .length; // 2 = validé
          }
        }
      } catch (e) {
        print('Erreur devis validés: $e');
      }

      // Récupérer les bordereaux validés
      try {
        final bordereauxResponse = await http.get(
          Uri.parse('$baseUrl/api/bordereaux-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (bordereauxResponse.statusCode == 200) {
          final bordereauxData = json.decode(bordereauxResponse.body);
          if (bordereauxData is List) {
            validatedBordereaux =
                bordereauxData
                    .where((bordereau) => bordereau['status'] == 2)
                    .length; // 2 = validé
          }
        }
      } catch (e) {
        print('Erreur bordereaux validés: $e');
      }

      // Récupérer les bons de commande validés
      try {
        final bonCommandesResponse = await http.get(
          Uri.parse('$baseUrl/api/bons-de-commande-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (bonCommandesResponse.statusCode == 200) {
          final bonCommandesData = json.decode(bonCommandesResponse.body);
          if (bonCommandesData['data'] != null &&
              bonCommandesData['data']['data'] is List) {
            validatedBonCommandes =
                bonCommandesData['data']['data']
                    .where((bon) => bon['status'] == 2)
                    .length; // 2 = validé
          }
        }
      } catch (e) {
        print('Erreur bons de commande validés: $e');
      }

      return {
        'clients': validatedClients,
        'devis': validatedDevis,
        'bordereaux': validatedBordereaux,
        'bon_commandes': validatedBonCommandes,
      };
    } catch (e) {
      print('Erreur: $e');
      return {'clients': 0, 'devis': 0, 'bordereaux': 0, 'bon_commandes': 0};
    }
  }

  // Récupérer les statistiques montants
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = storage.read('token');
      double totalRevenue = 0.0;
      double pendingDevisAmount = 0.0;
      double paidBordereauxAmount = 0.0;

      // Calculer le chiffre d'affaires total à partir des bordereaux payés
      try {
        final bordereauxResponse = await http.get(
          Uri.parse('$baseUrl/api/bordereaux-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (bordereauxResponse.statusCode == 200) {
          final bordereauxData = json.decode(bordereauxResponse.body);
          if (bordereauxData is List) {
            for (var bordereau in bordereauxData) {
              if (bordereau['status'] == 2) {
                // Status payé
                if (bordereau['items'] != null) {
                  for (var item in bordereau['items']) {
                    double prix =
                        double.tryParse(
                          item['prix_unitaire']?.toString() ?? '0',
                        ) ??
                        0;
                    int quantite =
                        int.tryParse(item['quantite']?.toString() ?? '0') ?? 0;
                    totalRevenue += prix * quantite;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Erreur calcul CA: $e');
      }

      // Calculer le montant des devis en attente
      try {
        final devisResponse = await http.get(
          Uri.parse('$baseUrl/api/devis-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (devisResponse.statusCode == 200) {
          final devisData = json.decode(devisResponse.body);
          if (devisData is List) {
            for (var devis in devisData) {
              if (devis['status'] == 0) {
                // Status en attente
                if (devis['items'] != null) {
                  for (var item in devis['items']) {
                    double prix =
                        double.tryParse(
                          item['prix_unitaire']?.toString() ?? '0',
                        ) ??
                        0;
                    int quantite =
                        int.tryParse(item['quantite']?.toString() ?? '0') ?? 0;
                    pendingDevisAmount += prix * quantite;
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Erreur calcul devis en attente: $e');
      }

      // Le montant des bordereaux payés est déjà calculé dans totalRevenue
      paidBordereauxAmount = totalRevenue;

      return {
        'total_revenue': totalRevenue,
        'pending_devis_amount': pendingDevisAmount,
        'paid_bordereaux_amount': paidBordereauxAmount,
      };
    } catch (e) {
      print('Erreur: $e');
      return {
        'total_revenue': 0.0,
        'pending_devis_amount': 0.0,
        'paid_bordereaux_amount': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/commercial/dashboard/data'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception(
        'Erreur lors de la récupération des données du dashboard: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur: $e');
      return {
        'pending_entities': {
          'clients': 0,
          'devis': 0,
          'bordereaux': 0,
          'bon_commandes': 0,
        },
        'validated_entities': {
          'clients': 0,
          'devis': 0,
          'bordereaux': 0,
          'bon_commandes': 0,
        },
        'statistics': {
          'total_revenue': 0.0,
          'pending_devis_amount': 0.0,
          'paid_bordereaux_amount': 0.0,
        },
      };
    }
  }
}
