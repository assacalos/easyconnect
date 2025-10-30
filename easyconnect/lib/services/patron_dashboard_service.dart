import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/utils/constant.dart';

class PatronDashboardService {
  final storage = GetStorage();

  // Récupérer les données de validation en attente
  Future<Map<String, int>> getPendingValidations() async {
    print('🚀 PatronDashboardService.getPendingValidations - Début');
    try {
      final token = storage.read('token');
      if (token == null) {
        print('❌ Patron - Token manquant!');
        return {
          'clients': 0,
          'proformas': 0,
          'bordereaux': 0,
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
          'reporting': 0,
          'pointages': 0,
        };
      }

      // Compteurs pour les validations en attente (tous rôles confondus)
      int pendingClients = 0;
      int pendingDevis = 0;
      int pendingBordereaux = 0;
      int pendingFactures = 0;
      int pendingPaiements = 0;
      int pendingDepenses = 0;
      int pendingSalaires = 0;
      int pendingReporting = 0;
      int pendingPointages = 0;

      // Récupérer les clients en attente
      try {
        final clientsResponse = await http.get(
          Uri.parse('$baseUrl/clients-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Clients response status: ${clientsResponse.statusCode}',
        );
        if (clientsResponse.statusCode == 200) {
          final clientsData = json.decode(clientsResponse.body);
          print('📊 Patron - Clients data type: ${clientsData.runtimeType}');
          print('📊 Patron - Clients data: $clientsData');
          List clientsList = [];
          if (clientsData is List) {
            clientsList = clientsData;
            print(
              '📊 Patron - Clients est une liste directe: ${clientsList.length} éléments',
            );
          } else if (clientsData is Map) {
            print('📊 Patron - Clients est un Map, clés: ${clientsData.keys}');
            if (clientsData['data'] != null) {
              if (clientsData['data'] is List) {
                clientsList = clientsData['data'];
                print(
                  '📊 Patron - Clients dans data: ${clientsList.length} éléments',
                );
              } else if (clientsData['data'] is Map &&
                  clientsData['data']['data'] != null) {
                if (clientsData['data']['data'] is List) {
                  clientsList = clientsData['data']['data'];
                  print(
                    '📊 Patron - Clients dans data.data: ${clientsList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Clients list length: ${clientsList.length}');
          if (clientsList.isNotEmpty) {
            print('📊 Patron - First client: ${clientsList[0]}');
            print(
              '📊 Patron - First client status: ${clientsList[0]['status']}',
            );
          }
          pendingClients =
              clientsList
                  .where(
                    (client) =>
                        client['status'] == 0 || client['status'] == null,
                  )
                  .length; // 0 = en attente pour clients
          print('📊 Patron - ✅ Pending clients: $pendingClients');
        } else {
          print(
            '❌ Patron - Clients response error: ${clientsResponse.statusCode} - ${clientsResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur clients: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer les devis en attente
      try {
        final devisResponse = await http.get(
          Uri.parse('$baseUrl/devis-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('📊 Patron - Devis response status: ${devisResponse.statusCode}');
        if (devisResponse.statusCode == 200) {
          final devisData = json.decode(devisResponse.body);
          print('📊 Patron - Devis data type: ${devisData.runtimeType}');
          List devisList = [];
          if (devisData is List) {
            devisList = devisData;
            print(
              '📊 Patron - Devis est une liste directe: ${devisList.length} éléments',
            );
          } else if (devisData is Map) {
            print('📊 Patron - Devis est un Map, clés: ${devisData.keys}');
            if (devisData['data'] != null) {
              if (devisData['data'] is List) {
                devisList = devisData['data'];
                print(
                  '📊 Patron - Devis dans data: ${devisList.length} éléments',
                );
              } else if (devisData['data'] is Map &&
                  devisData['data']['data'] != null) {
                if (devisData['data']['data'] is List) {
                  devisList = devisData['data']['data'];
                  print(
                    '📊 Patron - Devis dans data.data: ${devisList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Devis list length: ${devisList.length}');
          if (devisList.isNotEmpty) {
            print('📊 Patron - First devis status: ${devisList[0]['status']}');
          }
          pendingDevis =
              devisList
                  .where((devis) => devis['status'] == 1)
                  .length; // 1 = en attente
          print('📊 Patron - ✅ Pending devis: $pendingDevis');
        } else {
          print(
            '❌ Patron - Devis response error: ${devisResponse.statusCode} - ${devisResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur devis: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer les bordereaux en attente
      try {
        final bordereauxResponse = await http.get(
          Uri.parse('$baseUrl/bordereaux-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Bordereaux response status: ${bordereauxResponse.statusCode}',
        );
        if (bordereauxResponse.statusCode == 200) {
          final bordereauxData = json.decode(bordereauxResponse.body);
          print(
            '📊 Patron - Bordereaux data type: ${bordereauxData.runtimeType}',
          );
          List bordereauxList = [];
          if (bordereauxData is List) {
            bordereauxList = bordereauxData;
            print(
              '📊 Patron - Bordereaux est une liste directe: ${bordereauxList.length} éléments',
            );
          } else if (bordereauxData is Map) {
            print(
              '📊 Patron - Bordereaux est un Map, clés: ${bordereauxData.keys}',
            );
            if (bordereauxData['data'] != null) {
              if (bordereauxData['data'] is List) {
                bordereauxList = bordereauxData['data'];
                print(
                  '📊 Patron - Bordereaux dans data: ${bordereauxList.length} éléments',
                );
              } else if (bordereauxData['data'] is Map &&
                  bordereauxData['data']['data'] != null) {
                if (bordereauxData['data']['data'] is List) {
                  bordereauxList = bordereauxData['data']['data'];
                  print(
                    '📊 Patron - Bordereaux dans data.data: ${bordereauxList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Bordereaux list length: ${bordereauxList.length}');
          if (bordereauxList.isNotEmpty) {
            print(
              '📊 Patron - First bordereau status: ${bordereauxList[0]['status']}',
            );
          }
          pendingBordereaux =
              bordereauxList
                  .where((bordereau) => bordereau['status'] == 1)
                  .length; // 1 = en attente
          print('📊 Patron - ✅ Pending bordereaux: $pendingBordereaux');
        } else {
          print(
            '❌ Patron - Bordereaux response error: ${bordereauxResponse.statusCode} - ${bordereauxResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur bordereaux: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer les factures en attente
      try {
        final facturesResponse = await http.get(
          Uri.parse('$baseUrl/invoices-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Factures response status: ${facturesResponse.statusCode}',
        );
        if (facturesResponse.statusCode == 200) {
          final facturesData = json.decode(facturesResponse.body);
          print('📊 Patron - Factures data type: ${facturesData.runtimeType}');
          List facturesList = [];
          if (facturesData is List) {
            facturesList = facturesData;
            print(
              '📊 Patron - Factures est une liste directe: ${facturesList.length} éléments',
            );
          } else if (facturesData is Map) {
            print(
              '📊 Patron - Factures est un Map, clés: ${facturesData.keys}',
            );
            if (facturesData['data'] != null) {
              if (facturesData['data'] is List) {
                facturesList = facturesData['data'];
                print(
                  '📊 Patron - Factures dans data: ${facturesList.length} éléments',
                );
              } else if (facturesData['data'] is Map &&
                  facturesData['data']['data'] != null) {
                if (facturesData['data']['data'] is List) {
                  facturesList = facturesData['data']['data'];
                  print(
                    '📊 Patron - Factures dans data.data: ${facturesList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Factures list length: ${facturesList.length}');
          if (facturesList.isNotEmpty) {
            print(
              '📊 Patron - First facture status: ${facturesList[0]['status']}',
            );
          }
          pendingFactures =
              facturesList
                  .where((facture) => facture['status'] == 'draft')
                  .length; // 'draft' = en attente
          print('📊 Patron - ✅ Pending factures: $pendingFactures');
        } else {
          print(
            '❌ Patron - Factures response error: ${facturesResponse.statusCode} - ${facturesResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur factures: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer TOUS les paiements (tous statuts) pour compter ceux en attente
      try {
        final paiementsResponse = await http.get(
          Uri.parse('$baseUrl/payments-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Paiements response status: ${paiementsResponse.statusCode}',
        );
        if (paiementsResponse.statusCode == 200) {
          final paiementsData = json.decode(paiementsResponse.body);
          print(
            '📊 Patron - Paiements data type: ${paiementsData.runtimeType}',
          );
          List paiementsList = [];
          if (paiementsData is List) {
            paiementsList = paiementsData;
            print(
              '📊 Patron - Paiements est une liste directe: ${paiementsList.length} éléments',
            );
          } else if (paiementsData is Map) {
            print(
              '📊 Patron - Paiements est un Map, clés: ${paiementsData.keys}',
            );
            if (paiementsData['data'] != null) {
              if (paiementsData['data'] is List) {
                paiementsList = paiementsData['data'];
                print(
                  '📊 Patron - Paiements dans data: ${paiementsList.length} éléments',
                );
              } else if (paiementsData['data'] is Map &&
                  paiementsData['data']['data'] != null) {
                if (paiementsData['data']['data'] is List) {
                  paiementsList = paiementsData['data']['data'];
                  print(
                    '📊 Patron - Paiements dans data.data: ${paiementsList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Paiements list length: ${paiementsList.length}');
          if (paiementsList.isNotEmpty) {
            print(
              '📊 Patron - First paiement status: ${paiementsList[0]['status']}',
            );
          }
          // Compter tous les paiements en attente (status = 'pending' ou 'submitted')
          pendingPaiements =
              paiementsList
                  .where(
                    (paiement) =>
                        paiement['status'] == 'pending' ||
                        paiement['status'] == 'submitted',
                  )
                  .length;
          print(
            '📊 Patron - ✅ Pending paiements (tous rôles): $pendingPaiements',
          );
        } else {
          print(
            '❌ Patron - Paiements response error: ${paiementsResponse.statusCode} - ${paiementsResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur paiements: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer TOUTES les dépenses (tous statuts) pour compter celles en attente
      try {
        final depensesResponse = await http.get(
          Uri.parse('$baseUrl/expenses-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Dépenses response status: ${depensesResponse.statusCode}',
        );
        if (depensesResponse.statusCode == 200) {
          final depensesData = json.decode(depensesResponse.body);
          print('📊 Patron - Dépenses data type: ${depensesData.runtimeType}');
          List depensesList = [];
          if (depensesData is List) {
            depensesList = depensesData;
            print(
              '📊 Patron - Dépenses est une liste directe: ${depensesList.length} éléments',
            );
          } else if (depensesData is Map) {
            print(
              '📊 Patron - Dépenses est un Map, clés: ${depensesData.keys}',
            );
            if (depensesData['data'] != null) {
              if (depensesData['data'] is List) {
                depensesList = depensesData['data'];
                print(
                  '📊 Patron - Dépenses dans data: ${depensesList.length} éléments',
                );
              } else if (depensesData['data'] is Map &&
                  depensesData['data']['data'] != null) {
                if (depensesData['data']['data'] is List) {
                  depensesList = depensesData['data']['data'];
                  print(
                    '📊 Patron - Dépenses dans data.data: ${depensesList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Dépenses list length: ${depensesList.length}');
          if (depensesList.isNotEmpty) {
            print(
              '📊 Patron - First dépense status: ${depensesList[0]['status']}',
            );
          }
          // Compter toutes les dépenses en attente (status = 'pending')
          pendingDepenses =
              depensesList
                  .where((depense) => depense['status'] == 'pending')
                  .length;
          print(
            '📊 Patron - ✅ Pending dépenses (tous rôles): $pendingDepenses',
          );
        } else {
          print(
            '❌ Patron - Dépenses response error: ${depensesResponse.statusCode} - ${depensesResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur dépenses: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer TOUS les salaires (tous statuts) pour compter ceux en attente
      try {
        final salariesResponse = await http.get(
          Uri.parse('$baseUrl/salaries-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Salaires response status: ${salariesResponse.statusCode}',
        );
        if (salariesResponse.statusCode == 200) {
          final salariesData = json.decode(salariesResponse.body);
          print('📊 Patron - Salaires data type: ${salariesData.runtimeType}');
          List salariesList = [];
          if (salariesData is List) {
            salariesList = salariesData;
            print(
              '📊 Patron - Salaires est une liste directe: ${salariesList.length} éléments',
            );
          } else if (salariesData is Map) {
            print(
              '📊 Patron - Salaires est un Map, clés: ${salariesData.keys}',
            );
            if (salariesData['data'] != null) {
              if (salariesData['data'] is List) {
                salariesList = salariesData['data'];
                print(
                  '📊 Patron - Salaires dans data: ${salariesList.length} éléments',
                );
              } else if (salariesData['data'] is Map &&
                  salariesData['data']['data'] != null) {
                if (salariesData['data']['data'] is List) {
                  salariesList = salariesData['data']['data'];
                  print(
                    '📊 Patron - Salaires dans data.data: ${salariesList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Salaires list length: ${salariesList.length}');
          if (salariesList.isNotEmpty) {
            print(
              '📊 Patron - First salaire status: ${salariesList[0]['status']}',
            );
          }
          // Compter tous les salaires en attente (status = 'pending')
          pendingSalaires =
              salariesList
                  .where((salary) => salary['status'] == 'pending')
                  .length;
          print(
            '📊 Patron - ✅ Pending salaires (tous rôles): $pendingSalaires',
          );
        } else {
          print(
            '❌ Patron - Salaires response error: ${salariesResponse.statusCode} - ${salariesResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur salaires: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer TOUS les rapports (tous statuts) pour compter ceux en attente
      try {
        final reportingResponse = await http.get(
          Uri.parse('$baseUrl/reporting-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Reporting response status: ${reportingResponse.statusCode}',
        );
        if (reportingResponse.statusCode == 200) {
          final reportingData = json.decode(reportingResponse.body);
          print(
            '📊 Patron - Reporting data type: ${reportingData.runtimeType}',
          );
          List reportingList = [];
          if (reportingData is List) {
            reportingList = reportingData;
            print(
              '📊 Patron - Reporting est une liste directe: ${reportingList.length} éléments',
            );
          } else if (reportingData is Map) {
            print(
              '📊 Patron - Reporting est un Map, clés: ${reportingData.keys}',
            );
            if (reportingData['data'] != null) {
              if (reportingData['data'] is List) {
                reportingList = reportingData['data'];
                print(
                  '📊 Patron - Reporting dans data: ${reportingList.length} éléments',
                );
              } else if (reportingData['data'] is Map &&
                  reportingData['data']['data'] != null) {
                if (reportingData['data']['data'] is List) {
                  reportingList = reportingData['data']['data'];
                  print(
                    '📊 Patron - Reporting dans data.data: ${reportingList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Reporting list length: ${reportingList.length}');
          if (reportingList.isNotEmpty) {
            print(
              '📊 Patron - First report status: ${reportingList[0]['status']}',
            );
          }
          // Compter tous les rapports en attente (status = 'submitted')
          pendingReporting =
              reportingList
                  .where((report) => report['status'] == 'submitted')
                  .length;
          print(
            '📊 Patron - ✅ Pending reporting (tous rôles): $pendingReporting',
          );
        } else {
          print(
            '❌ Patron - Reporting response error: ${reportingResponse.statusCode} - ${reportingResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur reporting: $e');
        print('❌ Stack trace: $stackTrace');
      }

      // Récupérer TOUS les pointages (tous statuts) pour compter ceux en attente
      try {
        final pointagesResponse = await http.get(
          Uri.parse('$baseUrl/attendance-punch-list'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print(
          '📊 Patron - Pointages response status: ${pointagesResponse.statusCode}',
        );
        if (pointagesResponse.statusCode == 200) {
          final pointagesData = json.decode(pointagesResponse.body);
          print(
            '📊 Patron - Pointages data type: ${pointagesData.runtimeType}',
          );
          List pointagesList = [];
          if (pointagesData is List) {
            pointagesList = pointagesData;
            print(
              '📊 Patron - Pointages est une liste directe: ${pointagesList.length} éléments',
            );
          } else if (pointagesData is Map) {
            print(
              '📊 Patron - Pointages est un Map, clés: ${pointagesData.keys}',
            );
            if (pointagesData['data'] != null) {
              if (pointagesData['data'] is List) {
                pointagesList = pointagesData['data'];
                print(
                  '📊 Patron - Pointages dans data: ${pointagesList.length} éléments',
                );
              } else if (pointagesData['data'] is Map &&
                  pointagesData['data']['data'] != null) {
                if (pointagesData['data']['data'] is List) {
                  pointagesList = pointagesData['data']['data'];
                  print(
                    '📊 Patron - Pointages dans data.data: ${pointagesList.length} éléments',
                  );
                }
              }
            }
          }
          print('📊 Patron - Pointages list length: ${pointagesList.length}');
          if (pointagesList.isNotEmpty) {
            print(
              '📊 Patron - First pointage status: ${pointagesList[0]['status']}',
            );
          }
          // Compter tous les pointages en attente (status = 'pending')
          pendingPointages =
              pointagesList
                  .where((pointage) => pointage['status'] == 'pending')
                  .length;
          print(
            '📊 Patron - ✅ Pending pointages (tous rôles): $pendingPointages',
          );
        } else {
          print(
            '❌ Patron - Pointages response error: ${pointagesResponse.statusCode} - ${pointagesResponse.body}',
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erreur pointages: $e');
        print('❌ Stack trace: $stackTrace');
      }

      final result = {
        'clients': pendingClients,
        'proformas': pendingDevis, // proformas = devis
        'bordereaux': pendingBordereaux,
        'factures': pendingFactures,
        'paiements': pendingPaiements,
        'depenses': pendingDepenses,
        'salaires': pendingSalaires,
        'reporting': pendingReporting,
        'pointages': pendingPointages,
      };
      print(
        '✅ PatronDashboardService.getPendingValidations - Résultat: $result',
      );
      return result;
    } catch (e, stackTrace) {
      print('❌ Erreur globale PatronDashboardService: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'clients': 0,
        'proformas': 0,
        'bordereaux': 0,
        'factures': 0,
        'paiements': 0,
        'depenses': 0,
        'salaires': 0,
        'reporting': 0,
        'pointages': 0,
      };
    }
  }

  // Récupérer les métriques de performance
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/patron/dashboard/performance-metrics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];
        return {
          'validated_clients': data['validated_clients'] ?? 0,
          'total_employees': data['total_employees'] ?? 0,
          'total_suppliers': data['total_suppliers'] ?? 0,
          'total_revenue': (data['total_revenue'] ?? 0).toDouble(),
        };
      }
      throw Exception(
        'Erreur lors de la récupération des métriques: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur: $e');
      // Retourner des données par défaut en cas d'erreur
      return {
        'validated_clients': 0,
        'total_employees': 0,
        'total_suppliers': 0,
        'total_revenue': 0.0,
      };
    }
  }

  // Récupérer les données complètes du dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/patron/dashboard/data'),
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
      // Retourner des données par défaut en cas d'erreur
      return {
        'pending_validations': {
          'clients': 0,
          'proformas': 0,
          'bordereaux': 0,
          'factures': 0,
          'paiements': 0,
          'depenses': 0,
          'salaires': 0,
          'reporting': 0,
          'pointages': 0,
        },
        'performance_metrics': {
          'validated_clients': 0,
          'total_employees': 0,
          'total_suppliers': 0,
          'total_revenue': 0.0,
        },
      };
    }
  }
}
