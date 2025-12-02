import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class EmployeeService extends GetxService {
  static EmployeeService get to => Get.find();

  /// Récupérer les employés avec pagination côté serveur
  ///
  /// Le backend Laravel doit retourner une réponse paginée au format :
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "data": [...],
  ///     "current_page": 1,
  ///     "last_page": 5,
  ///     "per_page": 15,
  ///     "total": 100,
  ///     ...
  ///   }
  /// }
  Future<PaginationResponse<Employee>> getEmployeesPaginated({
    String? search,
    String? department,
    String? position,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    print('📡 [EMPLOYEE_SERVICE] ===== getEmployeesPaginated APPELÉ =====');
    print(
      '📡 [EMPLOYEE_SERVICE] Paramètres: search=$search, department=$department, position=$position, status=$status, page=$page, perPage=$perPage',
    );

    try {
      String url = '${AppConfig.baseUrl}/employees';
      List<String> params = [];
      print('📡 [EMPLOYEE_SERVICE] URL de base: $url');

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (department != null && department.isNotEmpty) {
        params.add('department=$department');
      }
      if (position != null && position.isNotEmpty) {
        params.add('position=$position');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      // Construire l'URL avec les paramètres
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      print('📡 [EMPLOYEE_SERVICE] URL finale: $url');

      http.Response response;
      try {
        print('📡 [EMPLOYEE_SERVICE] Tentative GET sur $url...');
        response = await http.get(
          Uri.parse(url),
          headers: ApiService.headers(),
        );
        print(
          '✅ [EMPLOYEE_SERVICE] Réponse reçue: status=${response.statusCode}, body length=${response.body.length}',
        );
      } catch (e) {
        print(
          '⚠️ [EMPLOYEE_SERVICE] Erreur avec /employees, tentative avec /employees-list: $e',
        );
        // Si la route /employees échoue, essayer /employees-list
        url = '${AppConfig.baseUrl}/employees-list';
        if (params.isNotEmpty) {
          url += '?${params.join('&')}';
        }
        print('📡 [EMPLOYEE_SERVICE] Nouvelle tentative sur: $url');
        response = await http.get(
          Uri.parse(url),
          headers: ApiService.headers(),
        );
        print(
          '✅ [EMPLOYEE_SERVICE] Réponse fallback: status=${response.statusCode}, body length=${response.body.length}',
        );
      }

      // Ne pas appeler AuthErrorHandler si c'est une erreur 500 (pour permettre le fallback)
      if (response.statusCode != 200 && response.statusCode != 500) {
        await AuthErrorHandler.handleHttpResponse(response);
      }

      if (response.statusCode == 200) {
        print('🔍 [EMPLOYEE_SERVICE] Parsing de la réponse JSON...');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔍 [EMPLOYEE_SERVICE] Structure JSON: ${data.keys.toList()}');

        // Utiliser PaginationHelper pour parser la réponse
        PaginationResponse<Employee> paginatedResponse;
        try {
          print('🔍 [EMPLOYEE_SERVICE] Tentative avec PaginationHelper...');
          paginatedResponse = PaginationHelper.parseResponse<Employee>(
            json: data,
            fromJsonT: (json) => Employee.fromJson(json),
          );
          print(
            '✅ [EMPLOYEE_SERVICE] PaginationHelper réussi: ${paginatedResponse.data.length} employés',
          );
        } catch (e, stackTrace) {
          print('❌ [EMPLOYEE_SERVICE] Erreur avec PaginationHelper: $e');
          print('❌ [EMPLOYEE_SERVICE] Stack trace: $stackTrace');

          // Fallback si PaginationHelper échoue
          AppLogger.warning(
            'Erreur avec PaginationHelper, parsing manuel: $e',
            tag: 'EMPLOYEE_SERVICE',
          );
          print(
            '🔄 [EMPLOYEE_SERVICE] Tentative de parsing manuel en fallback...',
          );

          List<Employee> fallbackData = [];
          if (data.containsKey('data')) {
            final dataValue = data['data'];
            print(
              '🔍 [EMPLOYEE_SERVICE] Fallback: dataValue type=${dataValue.runtimeType}',
            );

            if (dataValue is List) {
              print(
                '🔍 [EMPLOYEE_SERVICE] Fallback: dataValue est une List avec ${dataValue.length} éléments',
              );
              fallbackData =
                  dataValue
                      .map((json) {
                        try {
                          return Employee.fromJson(
                            json as Map<String, dynamic>,
                          );
                        } catch (e) {
                          print(
                            '❌ [EMPLOYEE_SERVICE] Fallback: Erreur parsing employé: $e',
                          );
                          AppLogger.warning(
                            'Erreur parsing employé: $e',
                            tag: 'EMPLOYEE_SERVICE',
                          );
                          return null;
                        }
                      })
                      .where((e) => e != null)
                      .cast<Employee>()
                      .toList();
              print(
                '✅ [EMPLOYEE_SERVICE] Fallback: ${fallbackData.length} employés parsés depuis List',
              );
            } else if (dataValue is Map &&
                dataValue.containsKey('data') &&
                dataValue['data'] is List) {
              final dataList = dataValue['data'] as List;
              print(
                '🔍 [EMPLOYEE_SERVICE] Fallback: dataValue est un Map avec data List de ${dataList.length} éléments',
              );
              fallbackData =
                  dataList
                      .map((json) {
                        try {
                          return Employee.fromJson(
                            json as Map<String, dynamic>,
                          );
                        } catch (e) {
                          print(
                            '❌ [EMPLOYEE_SERVICE] Fallback: Erreur parsing employé: $e',
                          );
                          AppLogger.warning(
                            'Erreur parsing employé: $e',
                            tag: 'EMPLOYEE_SERVICE',
                          );
                          return null;
                        }
                      })
                      .where((e) => e != null)
                      .cast<Employee>()
                      .toList();
              print(
                '✅ [EMPLOYEE_SERVICE] Fallback: ${fallbackData.length} employés parsés depuis Map.data',
              );
            } else {
              print(
                '⚠️ [EMPLOYEE_SERVICE] Fallback: Format de data non reconnu',
              );
            }
          } else {
            print(
              '⚠️ [EMPLOYEE_SERVICE] Fallback: Pas de clé "data" dans la réponse',
            );
          }

          // Créer une PaginationResponse factice
          paginatedResponse = PaginationResponse<Employee>(
            data: fallbackData,
            meta: PaginationMeta(
              currentPage: page,
              lastPage: 1,
              perPage: fallbackData.length,
              total: fallbackData.length,
              path: url,
            ),
          );
          print(
            '✅ [EMPLOYEE_SERVICE] PaginationResponse créée avec ${paginatedResponse.data.length} employés',
          );
        }

        if (paginatedResponse.data.isNotEmpty) {
          print(
            '📝 [EMPLOYEE_SERVICE] Premier employé parsé: id=${paginatedResponse.data.first.id}, name=${paginatedResponse.data.first.firstName} ${paginatedResponse.data.first.lastName}',
          );
        }

        return paginatedResponse;
      } else {
        // Si erreur 500 ou autre, essayer /employees-list en fallback
        print(
          '⚠️ [EMPLOYEE_SERVICE] Erreur ${response.statusCode} avec /employees, tentative avec /employees-list...',
        );
        try {
          String fallbackUrl = '${AppConfig.baseUrl}/employees-list';
          if (params.isNotEmpty) {
            fallbackUrl += '?${params.join('&')}';
          }
          print('📡 [EMPLOYEE_SERVICE] Tentative fallback sur: $fallbackUrl');

          final fallbackResponse = await http.get(
            Uri.parse(fallbackUrl),
            headers: ApiService.headers(),
          );

          print(
            '✅ [EMPLOYEE_SERVICE] Réponse fallback: status=${fallbackResponse.statusCode}, body length=${fallbackResponse.body.length}',
          );

          if (fallbackResponse.statusCode == 200) {
            print(
              '🔍 [EMPLOYEE_SERVICE] Parsing de la réponse fallback JSON...',
            );
            final fallbackData =
                jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
            print(
              '🔍 [EMPLOYEE_SERVICE] Structure JSON fallback: ${fallbackData.keys.toList()}',
            );

            // Utiliser PaginationHelper pour parser la réponse
            PaginationResponse<Employee> paginatedResponse;
            try {
              print(
                '🔍 [EMPLOYEE_SERVICE] Tentative avec PaginationHelper (fallback)...',
              );
              paginatedResponse = PaginationHelper.parseResponse<Employee>(
                json: fallbackData,
                fromJsonT: (json) => Employee.fromJson(json),
              );
              print(
                '✅ [EMPLOYEE_SERVICE] PaginationHelper réussi (fallback): ${paginatedResponse.data.length} employés',
              );
            } catch (e, stackTrace) {
              print(
                '❌ [EMPLOYEE_SERVICE] Erreur avec PaginationHelper (fallback): $e',
              );
              print('❌ [EMPLOYEE_SERVICE] Stack trace: $stackTrace');

              // Fallback manuel
              List<Employee> fallbackDataList = [];
              if (fallbackData.containsKey('data')) {
                final dataValue = fallbackData['data'];
                if (dataValue is List) {
                  fallbackDataList =
                      dataValue
                          .map((json) {
                            try {
                              return Employee.fromJson(
                                json as Map<String, dynamic>,
                              );
                            } catch (e) {
                              print(
                                '❌ [EMPLOYEE_SERVICE] Fallback: Erreur parsing employé: $e',
                              );
                              return null;
                            }
                          })
                          .where((e) => e != null)
                          .cast<Employee>()
                          .toList();
                }
              }

              paginatedResponse = PaginationResponse<Employee>(
                data: fallbackDataList,
                meta: PaginationMeta(
                  currentPage: page,
                  lastPage: 1,
                  perPage: fallbackDataList.length,
                  total: fallbackDataList.length,
                  path: fallbackUrl,
                ),
              );
              print(
                '✅ [EMPLOYEE_SERVICE] PaginationResponse créée (fallback manuel): ${paginatedResponse.data.length} employés',
              );
            }

            if (paginatedResponse.data.isNotEmpty) {
              print(
                '📝 [EMPLOYEE_SERVICE] Premier employé parsé (fallback): id=${paginatedResponse.data.first.id}, name=${paginatedResponse.data.first.firstName} ${paginatedResponse.data.first.lastName}',
              );
            }

            return paginatedResponse;
          } else {
            throw Exception(
              'Erreur lors de la récupération des employés: ${response.statusCode} - ${response.body} (fallback aussi échoué: ${fallbackResponse.statusCode})',
            );
          }
        } catch (fallbackError) {
          print(
            '❌ [EMPLOYEE_SERVICE] Le fallback vers /employees-list a aussi échoué: $fallbackError',
          );
          throw Exception(
            'Erreur lors de la récupération des employés: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération paginée des employés: $e',
        tag: 'EMPLOYEE_SERVICE',
        error: e,
      );
      rethrow;
    }
  }

  // Récupérer tous les employés (méthode legacy pour compatibilité)
  // Note: Cette méthode charge toutes les pages automatiquement
  Future<List<Employee>> getEmployees({
    String? search,
    String? department,
    String? position,
    String? status,
    int? page,
    int? limit,
  }) async {
    // Si aucune limite n'est spécifiée, utiliser une limite par défaut pour éviter les réponses trop grandes
    final effectiveLimit = limit ?? 50;
    final effectivePage = page ?? 1;

    // OPTIMISATION : Vérifier le cache d'abord (sauf pour les recherches)
    if (search == null || search.isEmpty) {
      final cacheKey =
          'employees_${department ?? 'all'}_${position ?? 'all'}_${status ?? 'all'}_${effectivePage}_$effectiveLimit';
      final cached = CacheHelper.get<List<Employee>>(cacheKey);
      if (cached != null) {
        AppLogger.debug('Using cached employees', tag: 'EMPLOYEE_SERVICE');
        return cached;
      }
    }

    try {
      print('📡 [EMPLOYEE_SERVICE] Appel de getEmployeesPaginated...');
      print(
        '📡 [EMPLOYEE_SERVICE] Paramètres: search=$search, department=$department, position=$position, status=$status, page=$effectivePage, limit=$effectiveLimit',
      );

      // Utiliser la méthode paginée
      final paginatedResponse = await getEmployeesPaginated(
        search: search,
        department: department,
        position: position,
        status: status,
        page: effectivePage,
        perPage: effectiveLimit,
      );

      print(
        '✅ [EMPLOYEE_SERVICE] getEmployeesPaginated retourné: ${paginatedResponse.data.length} employés',
      );

      final employees = paginatedResponse.data;

      // Mettre en cache pour 5 minutes (sauf pour les recherches)
      if (search == null || search.isEmpty) {
        final cacheKey =
            'employees_${department ?? 'all'}_${position ?? 'all'}_${status ?? 'all'}_${effectivePage}_$effectiveLimit';
        CacheHelper.set(
          cacheKey,
          employees,
          duration: AppConfig.defaultCacheDuration,
        );
        print(
          '💾 [EMPLOYEE_SERVICE] Données mises en cache avec la clé: $cacheKey',
        );
      }

      if (employees.isNotEmpty) {
        print(
          '📝 [EMPLOYEE_SERVICE] Premier employé: id=${employees.first.id}, name=${employees.first.firstName} ${employees.first.lastName}',
        );
      }

      return employees;
    } catch (e, stackTrace) {
      print('❌ [EMPLOYEE_SERVICE] Erreur avec getEmployeesPaginated: $e');
      print('❌ [EMPLOYEE_SERVICE] Stack trace: $stackTrace');

      // Si la méthode paginée échoue, essayer de récupérer directement depuis /employees-list
      AppLogger.warning(
        'Erreur avec getEmployeesPaginated, tentative avec /employees-list: $e',
        tag: 'EMPLOYEE_SERVICE',
      );
      print(
        '🔄 [EMPLOYEE_SERVICE] Tentative avec /employees-list en fallback...',
      );

      try {
        String url = '${AppConfig.baseUrl}/employees-list';
        List<String> params = [];

        if (search != null && search.isNotEmpty) {
          params.add('search=$search');
        }
        if (department != null && department.isNotEmpty) {
          params.add('department=$department');
        }
        if (position != null && position.isNotEmpty) {
          params.add('position=$position');
        }
        if (status != null && status.isNotEmpty) {
          params.add('status=$status');
        }

        if (params.isNotEmpty) {
          url += '?${params.join('&')}';
        }

        final response = await http.get(
          Uri.parse(url),
          headers: ApiService.headers(),
        );

        await AuthErrorHandler.handleHttpResponse(response);

        if (response.statusCode == 200) {
          final decodedBody = jsonDecode(response.body);

          // Gérer différents formats de réponse
          List<dynamic> dataList = [];

          if (decodedBody is List) {
            dataList = decodedBody;
          } else if (decodedBody is Map) {
            if (decodedBody.containsKey('data')) {
              final dataValue = decodedBody['data'];
              if (dataValue is List) {
                dataList = dataValue;
              } else if (dataValue is Map &&
                  dataValue.containsKey('data') &&
                  dataValue['data'] is List) {
                dataList = dataValue['data'] as List;
              }
            }
          }

          final employees =
              dataList
                  .map((json) {
                    try {
                      return Employee.fromJson(json as Map<String, dynamic>);
                    } catch (e) {
                      AppLogger.warning(
                        'Erreur parsing employé: $e',
                        tag: 'EMPLOYEE_SERVICE',
                      );
                      return null;
                    }
                  })
                  .where((e) => e != null)
                  .cast<Employee>()
                  .toList();

          // Mettre en cache
          if (search == null || search.isEmpty) {
            final cacheKey =
                'employees_${department ?? 'all'}_${position ?? 'all'}_${status ?? 'all'}_${effectivePage}_$effectiveLimit';
            CacheHelper.set(
              cacheKey,
              employees,
              duration: AppConfig.defaultCacheDuration,
            );
          }

          AppLogger.info(
            '${employees.length} employés récupérés via fallback',
            tag: 'EMPLOYEE_SERVICE',
          );
          return employees;
        }
      } catch (fallbackError) {
        AppLogger.error(
          'Erreur dans le fallback getEmployees: $fallbackError',
          tag: 'EMPLOYEE_SERVICE',
        );
      }

      rethrow;
    }
  }

  // Récupérer un employé par ID
  Future<Employee> getEmployee(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Employee.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Créer un nouvel employé
  Future<Map<String, dynamic>> createEmployee({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final url = '${AppConfig.baseUrl}/employees';
      AppLogger.httpRequest('POST', url, tag: 'EMPLOYEE_SERVICE');

      // Préparer les données en filtrant les valeurs null
      final employeeData = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      };

      // Ajouter les champs optionnels seulement s'ils ne sont pas null
      if (phone != null && phone.isNotEmpty) employeeData['phone'] = phone;
      if (address != null && address.isNotEmpty)
        employeeData['address'] = address;
      if (birthDate != null) {
        employeeData['birth_date'] =
            birthDate.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }
      if (gender != null && gender.isNotEmpty) employeeData['gender'] = gender;
      if (maritalStatus != null && maritalStatus.isNotEmpty) {
        employeeData['marital_status'] = maritalStatus;
      }
      if (nationality != null && nationality.isNotEmpty) {
        employeeData['nationality'] = nationality;
      }
      if (idNumber != null && idNumber.isNotEmpty) {
        employeeData['id_number'] = idNumber;
      }
      if (socialSecurityNumber != null && socialSecurityNumber.isNotEmpty) {
        employeeData['social_security_number'] = socialSecurityNumber;
      }
      if (position != null && position.isNotEmpty)
        employeeData['position'] = position;
      if (department != null && department.isNotEmpty) {
        employeeData['department'] = department;
      }
      if (manager != null && manager.isNotEmpty)
        employeeData['manager'] = manager;
      if (hireDate != null) {
        employeeData['hire_date'] =
            hireDate.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }
      if (contractStartDate != null) {
        employeeData['contract_start_date'] =
            contractStartDate.toIso8601String().split('T')[0];
      }
      if (contractEndDate != null) {
        employeeData['contract_end_date'] =
            contractEndDate.toIso8601String().split('T')[0];
      }
      if (contractType != null && contractType.isNotEmpty) {
        employeeData['contract_type'] = contractType;
      }
      if (salary != null && salary > 0) employeeData['salary'] = salary;
      if (currency != null && currency.isNotEmpty)
        employeeData['currency'] = currency;
      if (workSchedule != null && workSchedule.isNotEmpty) {
        employeeData['work_schedule'] = workSchedule;
      }
      if (profilePicture != null && profilePicture.isNotEmpty) {
        employeeData['profile_picture'] = profilePicture;
      }
      if (notes != null && notes.isNotEmpty) employeeData['notes'] = notes;

      AppLogger.debug(
        'Données envoyées: ${jsonEncode(employeeData)}',
        tag: 'EMPLOYEE_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: ApiService.headers(),
              body: jsonEncode(employeeData),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'EMPLOYEE_SERVICE');

      // Logger le body de la réponse pour le débogage
      AppLogger.debug(
        'Réponse du backend (${response.statusCode}): ${response.body}',
        tag: 'EMPLOYEE_SERVICE',
      );

      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info('Employé créé avec succès', tag: 'EMPLOYEE_SERVICE');
        return jsonDecode(response.body);
      } else {
        // Extraire le message d'erreur détaillé du backend
        String errorMessage =
            'Erreur lors de la création de l\'employé: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            // Si c'est une erreur de validation Laravel
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e as List).join(', ');
            errorMessage = 'Erreurs de validation: $errorList';
          } else {
            // Si pas de message structuré, utiliser le body complet
            errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
          }
          AppLogger.error(
            'Erreur backend: $errorMessage',
            tag: 'EMPLOYEE_SERVICE',
          );
        } catch (e) {
          AppLogger.error(
            'Erreur lors du parsing de la réponse: ${response.body}',
            tag: 'EMPLOYEE_SERVICE',
            error: e,
          );
          // Si le parsing échoue, utiliser le body brut
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création de l\'employé: $e',
        tag: 'EMPLOYEE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Mettre à jour un employé
  Future<Map<String, dynamic>> updateEmployee({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? status,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/employees/$id'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'address': address,
          'birth_date': birthDate?.toIso8601String(),
          'gender': gender,
          'marital_status': maritalStatus,
          'nationality': nationality,
          'id_number': idNumber,
          'social_security_number': socialSecurityNumber,
          'position': position,
          'department': department,
          'manager': manager,
          'hire_date': hireDate?.toIso8601String(),
          'contract_start_date': contractStartDate?.toIso8601String(),
          'contract_end_date': contractEndDate?.toIso8601String(),
          'contract_type': contractType,
          'salary': salary,
          'currency': currency,
          'work_schedule': workSchedule,
          'status': status,
          'profile_picture': profilePicture,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un employé
  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre un employé pour approbation
  Future<Map<String, dynamic>> submitEmployeeForApproval(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la soumission: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un employé (pour le patron)
  Future<Map<String, dynamic>> approveEmployee(
    int id, {
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un employé (pour le patron)
  Future<Map<String, dynamic>> rejectEmployee(
    int id, {
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du rejet: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques des employés
  Future<EmployeeStats> getEmployeeStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/employees/stats'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmployeeStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les départements
  Future<List<String>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/employees/departments'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final departments = List<String>.from(data['data'] ?? []);
        // S'assurer que "Ressources Humaines" est toujours dans la liste
        if (departments.isNotEmpty) {
          if (!departments.contains('Ressources Humaines')) {
            departments.add('Ressources Humaines');
          }
          return departments;
        }
      }
      // Retourner des départements par défaut si le backend ne retourne rien
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ];
    } catch (e) {
      // Retourner des départements par défaut en cas d'erreur
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ];
    }
  }

  // Récupérer les postes
  Future<List<String>> getPositions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/employees/positions'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des postes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des documents d'employé
  Future<Map<String, dynamic>> addEmployeeDocument({
    required int employeeId,
    required String name,
    required String type,
    String? description,
    String? filePath,
    DateTime? expiryDate,
    bool isRequired = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/documents'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'file_path': filePath,
          'expiry_date': expiryDate?.toIso8601String(),
          'is_required': isRequired,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du document: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des congés d'employé
  Future<Map<String, dynamic>> addEmployeeLeave({
    required int employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/leaves'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'type': type,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un congé
  Future<Map<String, dynamic>> approveLeave(
    int leaveId, {
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/leaves/$leaveId/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un congé
  Future<Map<String, dynamic>> rejectLeave(
    int leaveId, {
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/leaves/$leaveId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des performances
  Future<Map<String, dynamic>> addEmployeePerformance({
    required int employeeId,
    required String period,
    required double rating,
    String? comments,
    String? goals,
    String? achievements,
    String? areasForImprovement,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/performances'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'period': period,
          'rating': rating,
          'comments': comments,
          'goals': goals,
          'achievements': achievements,
          'areas_for_improvement': areasForImprovement,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la performance: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rechercher des employés
  Future<List<Employee>> searchEmployees(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/employees/search?q=$query'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
