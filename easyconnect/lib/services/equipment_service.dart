import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/http_interceptor.dart';

class EquipmentService {
  /// Récupérer les équipements avec pagination côté serveur
  Future<PaginationResponse<Equipment>> getEquipmentsPaginated({
    String? status,
    String? category,
    String? condition,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final headers = await ApiService.headersAsync();
      String url = '${AppConfig.baseUrl}/equipment';
      List<String> params = [];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
      }
      if (condition != null && condition.isNotEmpty) {
        params.add('condition=$condition');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'EQUIPMENT_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(
              Uri.parse(url),
              headers: headers,
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'EQUIPMENT_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        debugPrint('🔍 [EQUIPMENT_SERVICE] Status 200, début du parsing...');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('🔍 [EQUIPMENT_SERVICE] Parsing de la réponse paginée...');
        debugPrint('🔍 [EQUIPMENT_SERVICE] Structure JSON: ${data.keys.toList()}');
        debugPrint(
          '🔍 [EQUIPMENT_SERVICE] Type de data: ${data['data']?.runtimeType}',
        );
        if (data['data'] is List) {
          debugPrint(
            '🔍 [EQUIPMENT_SERVICE] data est une List avec ${(data['data'] as List).length} éléments',
          );
        }

        try {
          final paginatedResponse = PaginationHelper.parseResponse<Equipment>(
            json: data,
            fromJsonT: (json) {
              debugPrint(
                '🔍 [EQUIPMENT_SERVICE] Parsing d\'un équipement depuis pagination...',
              );
              try {
                return Equipment.fromJson(json);
              } catch (e, stackTrace) {
                debugPrint(
                  '❌ [EQUIPMENT_SERVICE] Erreur lors du parsing d\'un équipement: $e',
                );
                debugPrint('❌ [EQUIPMENT_SERVICE] Stack trace: $stackTrace');
                debugPrint('❌ [EQUIPMENT_SERVICE] JSON: $json');
                rethrow;
              }
            },
          );

          debugPrint(
            '🔍 [EQUIPMENT_SERVICE] Réponse paginée parsée: ${paginatedResponse.data.length} équipements',
          );
          if (paginatedResponse.data.isNotEmpty) {
            debugPrint(
              '🔍 [EQUIPMENT_SERVICE] Premier équipement: ${paginatedResponse.data.first.name}, status: ${paginatedResponse.data.first.status}',
            );
          } else {
            debugPrint(
              '⚠️ [EQUIPMENT_SERVICE] ATTENTION: La réponse paginée contient 0 équipements!',
            );
          }

          return paginatedResponse;
        } catch (e, stackTrace) {
          debugPrint(
            '❌ [EQUIPMENT_SERVICE] Erreur dans PaginationHelper.parseResponse: $e',
          );
          debugPrint('❌ [EQUIPMENT_SERVICE] Stack trace: $stackTrace');
          // Si le parsing échoue, essayer de parser manuellement
          if (data.containsKey('data') && data['data'] is List) {
            debugPrint('🔄 [EQUIPMENT_SERVICE] Tentative de parsing manuel...');
            final dataList = data['data'] as List;
            final equipments = <Equipment>[];
            for (var item in dataList) {
              try {
                if (item is Map<String, dynamic>) {
                  equipments.add(Equipment.fromJson(item));
                }
              } catch (e) {
                debugPrint(
                  '⚠️ [EQUIPMENT_SERVICE] Erreur lors du parsing manuel d\'un équipement: $e',
                );
              }
            }
            debugPrint(
              '🔄 [EQUIPMENT_SERVICE] Parsing manuel: ${equipments.length} équipements parsés',
            );
            return PaginationResponse<Equipment>(
              data: equipments,
              meta: PaginationMeta(
                currentPage: 1,
                lastPage: 1,
                perPage: equipments.length,
                total: equipments.length,
                path: '',
              ),
            );
          }
          rethrow;
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des équipements: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getEquipmentsPaginated: $e',
        tag: 'EQUIPMENT_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer tous les équipements
  Future<List<Equipment>> getEquipments({
    String? status,
    String? category,
    String? condition,
    String? search,
  }) async {
    try {
      final headers = await ApiService.headersAsync();

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (condition != null) queryParams['condition'] = condition;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await HttpInterceptor.get(
            Uri.parse('${AppConfig.baseUrl}/equipment-list$queryString'),
            headers: headers,
          )
          .timeout(
            AppConfig.extraLongTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        debugPrint(
          '🔍 [EQUIPMENT_SERVICE] Réponse brute (premiers 500 caractères): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
        );
        debugPrint(
          '🔍 [EQUIPMENT_SERVICE] Type de decodedBody: ${decodedBody.runtimeType}',
        );

        // Gérer différents formats de réponse
        List<dynamic> data = [];

        if (decodedBody is List) {
          // Si la réponse est directement une liste
          data = decodedBody;
        } else if (decodedBody is Map) {
          // Si la réponse est un objet Map
          if (decodedBody.containsKey('data')) {
            final dataValue = decodedBody['data'];
            if (dataValue is List) {
              // Si 'data' est une liste
              data = dataValue;
            } else if (dataValue is Map) {
              // Si 'data' est un Map, chercher les équipements dans différentes clés possibles
              final dataMap = dataValue as Map<String, dynamic>;

              // Gérer la pagination Laravel (structure: { "data": { "data": [...], "current_page": 1, ... } })
              if (dataMap.containsKey('data') && dataMap['data'] is List) {
                data = dataMap['data'] as List<dynamic>;
              } else if (dataMap.containsKey('equipments')) {
                final equipmentsList = dataMap['equipments'];
                if (equipmentsList is List) {
                  data = equipmentsList;
                }
              } else if (dataMap.containsKey('equipment')) {
                final equipmentList = dataMap['equipment'];
                if (equipmentList is List) {
                  data = equipmentList;
                }
              } else {
                // Si 'data' est un Map mais ne contient pas de liste, essayer de convertir les valeurs
                // Peut-être que les équipements sont directement dans les valeurs du Map
                data =
                    dataMap.values.whereType<Map<String, dynamic>>().toList();
              }
            }
          } else {
            // Si pas de clé 'data', chercher d'autres clés possibles
            if (decodedBody.containsKey('equipments')) {
              final equipmentsList = decodedBody['equipments'];
              if (equipmentsList is List) {
                data = equipmentsList;
              }
            } else if (decodedBody.containsKey('equipment')) {
              final equipmentList = decodedBody['equipment'];
              if (equipmentList is List) {
                data = equipmentList;
              }
            }
          }
        }

        // Parser les équipements
        final equipments = <Equipment>[];
        debugPrint(
          '🔍 [EQUIPMENT_SERVICE] Nombre d\'éléments à parser: ${data.length}',
        );
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              // Debug: Afficher le statut brut du JSON
              final rawStatus = item['status'];
              debugPrint(
                '🔍 [EQUIPMENT_SERVICE] Équipement "${item['name']}": status brut = $rawStatus (type: ${rawStatus.runtimeType})',
              );

              final equipment = Equipment.fromJson(item);
              debugPrint(
                '🔍 [EQUIPMENT_SERVICE] Équipement "${equipment.name}": status parsé = "${equipment.status}"',
              );
              equipments.add(equipment);
            }
          } catch (e, stackTrace) {
            debugPrint(
              '❌ [EQUIPMENT_SERVICE] Erreur lors du parsing d\'un équipement: $e',
            );
            debugPrint('❌ [EQUIPMENT_SERVICE] Stack trace: $stackTrace');
            debugPrint('❌ [EQUIPMENT_SERVICE] Item: $item');
            // Ignorer les éléments invalides mais continuer
          }
        }

        debugPrint(
          '🔍 [EQUIPMENT_SERVICE] Nombre d\'équipements parsés: ${equipments.length}',
        );
        if (equipments.isNotEmpty) {
          final allStatuses = equipments.map((e) => e.status).toSet();
          debugPrint('🔍 [EQUIPMENT_SERVICE] Tous les statuts parsés: $allStatuses');
        }

        _saveEquipmentsToHive(equipments);
        return equipments;
      }
      throw Exception(
        'Erreur lors de la récupération des équipements: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des équipements: $e');
    }
  }

  // Récupérer un équipement par ID
  Future<Equipment> getEquipmentById(int id) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération de l\'équipement: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'équipement: $e');
    }
  }

  // Créer un équipement
  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final headers = await ApiService.headersAsync();

      debugPrint(
        '📤 [EQUIPMENT_SERVICE] Envoi de la requête POST vers ${AppConfig.baseUrl}/equipment-create',
      );
      debugPrint('📤 [EQUIPMENT_SERVICE] Données: ${equipment.toJson()}');

      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/equipment-create'),
        headers: headers,
        body: json.encode(equipment.toJson()),
      );

      debugPrint(
        '📥 [EQUIPMENT_SERVICE] Réponse reçue: Status ${response.statusCode}',
      );
      debugPrint(
        '📥 [EQUIPMENT_SERVICE] Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        // Gérer différents formats de réponse
        Map<String, dynamic> equipmentData;
        if (decodedBody is Map && decodedBody.containsKey('data')) {
          final dataValue = decodedBody['data'];
          if (dataValue is Map) {
            equipmentData = dataValue as Map<String, dynamic>;
          } else {
            throw Exception('Format de réponse inattendu pour la création');
          }
        } else {
          throw Exception('Format de réponse inattendu pour la création');
        }

        debugPrint(
          '✅ [EQUIPMENT_SERVICE] Équipement créé avec succès: ID ${equipmentData['id']}',
        );
        return Equipment.fromJson(equipmentData);
      }

      // Gérer les erreurs 500 - vérifier si l'équipement a quand même été créé
      if (response.statusCode == 500) {
        debugPrint(
          '⚠️ [EQUIPMENT_SERVICE] Erreur 500 détectée, vérification si équipement créé...',
        );
        try {
          final errorBody = json.decode(response.body);
          debugPrint('📋 [EQUIPMENT_SERVICE] Body de l\'erreur: $errorBody');

          // Chercher un ID dans la réponse d'erreur
          int? equipmentId;
          if (errorBody is Map) {
            // Essayer différents chemins pour trouver l'ID
            if (errorBody['data'] != null && errorBody['data'] is Map) {
              final data = errorBody['data'] as Map<String, dynamic>;
              if (data['equipment'] != null && data['equipment'] is Map) {
                equipmentId = data['equipment']['id'] as int?;
              } else if (data['id'] != null) {
                equipmentId = data['id'] as int?;
              }
            } else if (errorBody['equipment'] != null &&
                errorBody['equipment'] is Map) {
              equipmentId = errorBody['equipment']['id'] as int?;
            } else if (errorBody['id'] != null) {
              equipmentId = errorBody['id'] as int?;
            }
          }

          if (equipmentId != null) {
            debugPrint(
              '✅ [EQUIPMENT_SERVICE] ID trouvé dans l\'erreur 500: $equipmentId',
            );
            // Construire un équipement avec l'ID trouvé
            final equipmentData = equipment.toJson();
            equipmentData['id'] = equipmentId;
            equipmentData['created_at'] = DateTime.now().toIso8601String();
            equipmentData['updated_at'] = DateTime.now().toIso8601String();

            debugPrint(
              '✅ [EQUIPMENT_SERVICE] Équipement retourné malgré l\'erreur 500: ID $equipmentId',
            );
            return Equipment.fromJson(equipmentData);
          } else {
            debugPrint('❌ [EQUIPMENT_SERVICE] Aucun ID trouvé dans l\'erreur 500');
          }
        } catch (e) {
          debugPrint(
            '⚠️ [EQUIPMENT_SERVICE] Erreur lors de l\'analyse de l\'erreur 500: $e',
          );
        }
      }

      debugPrint(
        '❌ [EQUIPMENT_SERVICE] Erreur ${response.statusCode}: ${response.body}',
      );
      throw Exception(
        'Erreur lors de la création de l\'équipement: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      debugPrint('❌ [EQUIPMENT_SERVICE] Exception capturée: $e');
      throw Exception('Erreur lors de la création de l\'équipement: $e');
    }
  }

  // Mettre à jour un équipement
  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.put(
        Uri.parse('${AppConfig.baseUrl}/equipment-update/${equipment.id}'),
        headers: headers,
        body: json.encode(equipment.toJson()),
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de l\'équipement: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'équipement: $e');
    }
  }

  // Supprimer un équipement
  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.delete(
        Uri.parse('${AppConfig.baseUrl}/equipment-destroy/$equipmentId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupérer les statistiques des équipements
  Future<EquipmentStats> getEquipmentStats() async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment-statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return EquipmentStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return EquipmentStats(
        totalEquipment: 0,
        activeEquipment: 0,
        inactiveEquipment: 0,
        maintenanceEquipment: 0,
        brokenEquipment: 0,
        retiredEquipment: 0,
        excellentCondition: 0,
        goodCondition: 0,
        fairCondition: 0,
        poorCondition: 0,
        criticalCondition: 0,
        needsMaintenance: 0,
        warrantyExpired: 0,
        warrantyExpiringSoon: 0,
        totalValue: 0.0,
        averageAge: 0.0,
        equipmentByCategory: {},
        equipmentByStatus: {},
        equipmentByCondition: {},
      );
    }
  }

  // Récupérer les catégories d'équipements
  Future<List<EquipmentCategory>> getEquipmentCategories() async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment-categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => EquipmentCategory.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des catégories: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Récupérer les équipements nécessitant une maintenance
  Future<List<Equipment>> getEquipmentsNeedingMaintenance() async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment-needs-maintenance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements nécessitant une maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements nécessitant une maintenance: $e',
      );
    }
  }

  // Récupérer les équipements avec garantie expirant bientôt
  Future<List<Equipment>> getEquipmentsWithWarrantyExpiringSoon() async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment-warranty-expiring-soon'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirant bientôt: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirant bientôt: $e',
      );
    }
  }

  // Récupérer les équipements avec garantie expirée
  Future<List<Equipment>> getEquipmentsWithExpiredWarranty() async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipment-warranty-expired'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirée: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirée: $e',
      );
    }
  }

  // Récupérer l'historique de maintenance d'un équipement
  Future<List<EquipmentMaintenance>> getEquipmentMaintenanceHistory(
    int equipmentId,
  ) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipments/$equipmentId/maintenance'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => EquipmentMaintenance.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération de l\'historique de maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération de l\'historique de maintenance: $e',
      );
    }
  }

  // Planifier une maintenance
  Future<EquipmentMaintenance> scheduleMaintenance(
    EquipmentMaintenance maintenance,
  ) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.post(
        Uri.parse(
          '${AppConfig.baseUrl}/equipment/${maintenance.equipmentId}/schedule-maintenance',
        ),
        headers: headers,
        body: json.encode(maintenance.toJson()),
      );

      if (response.statusCode == 201) {
        return EquipmentMaintenance.fromJson(
          json.decode(response.body)['data'],
        );
      }
      throw Exception(
        'Erreur lors de la planification de la maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la planification de la maintenance: $e');
    }
  }

  // Mettre à jour le statut d'un équipement
  Future<bool> updateEquipmentStatus(int equipmentId, String status) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.patch(
        Uri.parse('${AppConfig.baseUrl}/equipments/$equipmentId/status'),
        headers: headers,
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<bool> updateEquipmentCondition(
    int equipmentId,
    String condition,
  ) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.patch(
        Uri.parse('${AppConfig.baseUrl}/equipments/$equipmentId/condition'),
        headers: headers,
        body: json.encode({'condition': condition}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Assigner un équipement à un utilisateur
  Future<bool> assignEquipment(int equipmentId, String assignedTo) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/equipment/$equipmentId/assign'),
        headers: headers,
        body: json.encode({'assigned_to': assignedTo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Retourner un équipement (désassigner)
  Future<bool> returnEquipment(int equipmentId) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/equipment/$equipmentId/return'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Désassigner un équipement (alias pour compatibilité)
  Future<bool> unassignEquipment(int equipmentId) async {
    return returnEquipment(equipmentId);
  }

  // Ajouter une pièce jointe
  Future<bool> addAttachment(int equipmentId, String filePath) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/equipments/$equipmentId/attachments'),
        headers: headers,
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Supprimer une pièce jointe
  Future<bool> removeAttachment(int equipmentId, String filePath) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.delete(
        Uri.parse('${AppConfig.baseUrl}/equipments/$equipmentId/attachments'),
        headers: headers,
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Rechercher des équipements
  Future<List<Equipment>> searchEquipments(String query) async {
    try {
      final headers = await ApiService.headersAsync();

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/equipments/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la recherche d\'équipements: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'équipements: $e');
    }
  }

  static void _saveEquipmentsToHive(List<Equipment> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyEquipments,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Persiste la liste en cache Hive (appelé après création ou refresh API).
  static void saveEquipmentsToHive(List<Equipment> list) {
    _saveEquipmentsToHive(list);
  }

  /// Cache Hive : liste des équipements pour affichage instantané.
  static List<Equipment> getCachedEquipments() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyEquipments);
      return raw.map((e) => Equipment.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}
