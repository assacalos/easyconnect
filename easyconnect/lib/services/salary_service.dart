import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';

class SalaryService {
  final storage = GetStorage();

  // Tester la connectivité à l'API pour les salaires
  Future<bool> testSalaryConnection() async {
    try {
      final token = storage.read('token');

      final response = await http
          .get(
            Uri.parse('$baseUrl/salaries-list'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupérer tous les salaires
  Future<List<Salary>> getSalaries({
    String? status,
    String? month,
    int? year,
    String? search,
  }) async {
    try {
      final token = storage.read('token');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year.toString();
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/salaries-list$queryString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Gérer différents formats de réponse de l'API Laravel
          List<dynamic> data = [];

          // Essayer d'abord le format standard Laravel
          if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data']['data'] != null) {
              data = responseData['data']['data'];
            }
          }
          // Essayer le format spécifique aux salaires
          else if (responseData['salaries'] != null) {
            if (responseData['salaries'] is List) {
              data = responseData['salaries'];
            }
          }
          // Essayer le format avec success
          else if (responseData['success'] == true &&
              responseData['salaries'] != null) {
            if (responseData['salaries'] is List) {
              data = responseData['salaries'];
            }
          }
          if (data.isEmpty) {
            return [];
          }

          try {
            return data.map((json) {
              return Salary.fromJson(json);
            }).toList();
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des salaires: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un salaire par ID
  Future<Salary> getSalaryById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/salaries-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Salary.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération du salaire: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du salaire: $e');
    }
  }

  // Créer un salaire
  Future<Salary> createSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      // Validation des champs requis
      if (salary.employeeId == 0) {
        throw Exception('employeeId est requis');
      }
      if (salary.baseSalary <= 0) {
        throw Exception('baseSalary doit être supérieur à 0');
      }
      if (salary.month == null || salary.month!.isEmpty) {
        throw Exception('month est requis');
      }
      if (salary.year == null || salary.year! < 2000 || salary.year! > 2100) {
        throw Exception('year est requis et doit être entre 2000 et 2100');
      }

      // Formatage du mois selon la documentation API
      // La documentation accepte un entier (1-12) ou une string
      // On envoie un entier pour plus de simplicité
      int monthInt = int.tryParse(salary.month!) ?? 0;
      if (monthInt < 1 || monthInt > 12) {
        throw Exception('Le mois doit être entre 1 et 12');
      }

      // Préparer les données selon la documentation API
      // Le backend génère automatiquement : period, period_start, period_end, salary_date
      // Format snake_case comme recommandé dans la documentation
      final salaryData = {
        'employee_id':
            salary
                .employeeId, // ID de l'employé depuis la table employees (obligatoire)
        'base_salary': salary.baseSalary, // Salaire de base (obligatoire)
        'month': monthInt, // Mois (1-12) - format entier comme recommandé
        'year': salary.year!, // Année (obligatoire)
        // Champs optionnels
        if (salary.netSalary > 0) 'net_salary': salary.netSalary,
        if (salary.bonus > 0) 'bonus': salary.bonus,
        if (salary.deductions > 0) 'deductions': salary.deductions,
        if (salary.notes != null && salary.notes!.isNotEmpty)
          'notes': salary.notes,
        if (salary.justificatifs.isNotEmpty)
          'justificatif':
              salary
                  .justificatifs, // Note: le backend attend 'justificatif' (singulier) comme array
      };
      final response = await http.post(
        Uri.parse('$baseUrl/salaries-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salaryData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Salary.fromJson(responseBody['data'] ?? responseBody);
      }

      // Afficher les détails de l'erreur
      final errorBody = response.body;
      throw Exception(
        'Erreur lors de la création du salaire: ${response.statusCode} - $errorBody',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du salaire: $e');
    }
  }

  // Mettre à jour un salaire
  Future<Salary> updateSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      // Validation des champs requis
      if (salary.id == null) {
        throw Exception('salary.id est requis pour la mise à jour');
      }
      if (salary.employeeId == 0) {
        throw Exception('employeeId est requis');
      }
      if (salary.baseSalary <= 0) {
        throw Exception('baseSalary doit être supérieur à 0');
      }
      if (salary.month == null || salary.month!.isEmpty) {
        throw Exception('month est requis');
      }
      if (salary.year == null || salary.year! < 2000 || salary.year! > 2100) {
        throw Exception('year est requis et doit être entre 2000 et 2100');
      }

      // Formatage du mois selon la documentation API
      // La documentation accepte un entier (1-12) ou une string
      // On envoie un entier pour plus de simplicité
      int monthInt = int.tryParse(salary.month!) ?? 0;
      if (monthInt < 1 || monthInt > 12) {
        throw Exception('Le mois doit être entre 1 et 12');
      }

      // Préparer les données selon la documentation API
      // Le backend génère automatiquement : period, period_start, period_end, salary_date
      // Format snake_case comme recommandé dans la documentation
      final salaryData = {
        'employee_id':
            salary.employeeId, // ID de l'employé depuis la table employees
        'base_salary': salary.baseSalary, // Salaire de base
        'month': monthInt, // Mois (1-12) - format entier comme recommandé
        'year': salary.year!, // Année
        // Champs optionnels
        if (salary.netSalary > 0) 'net_salary': salary.netSalary,
        if (salary.bonus > 0) 'bonus': salary.bonus,
        if (salary.deductions > 0) 'deductions': salary.deductions,
        if (salary.status != null) 'status': salary.status,
        if (salary.notes != null && salary.notes!.isNotEmpty)
          'notes': salary.notes,
        if (salary.justificatifs.isNotEmpty)
          'justificatif':
              salary
                  .justificatifs, // Note: le backend attend 'justificatif' (singulier) comme array
      };
      final response = await http.put(
        Uri.parse('$baseUrl/salaries-update/${salary.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salaryData),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Salary.fromJson(responseBody['data'] ?? responseBody);
      }

      // Afficher les détails de l'erreur
      final errorBody = response.body;
      throw Exception(
        'Erreur lors de la mise à jour du salaire: ${response.statusCode} - $errorBody',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du salaire: $e');
    }
  }

  // Approuver un salaire
  Future<bool> approveSalary(int salaryId, {String? notes}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/salaries-validate/$salaryId';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Ce salaire ne peut pas être approuvé';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de l\'approbation';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter un salaire
  Future<bool> rejectSalary(int salaryId, {required String reason}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/salaries-reject/$salaryId';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Ce salaire ne peut pas être rejeté';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Marquer comme payé
  Future<bool> markSalaryAsPaid(int salaryId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/salaries/$salaryId/pay'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un salaire
  Future<bool> deleteSalary(int salaryId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/salaries-delete/$salaryId'),
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

  // Récupérer les statistiques des salaires
  Future<SalaryStats> getSalaryStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/salaries/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return SalaryStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return SalaryStats(
        totalSalaries: 0.0,
        pendingSalaries: 0.0,
        approvedSalaries: 0.0,
        paidSalaries: 0.0,
        totalEmployees: 0,
        pendingCount: 0,
        approvedCount: 0,
        paidCount: 0,
        salariesByMonth: {},
        countByMonth: {},
      );
    }
  }

  // Récupérer les salaires en attente
  Future<List<Salary>> getPendingSalaries() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/salaries-pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dynamic data = responseData['data'];

        // Gérer le cas où data est une liste ou un objet
        if (data is List) {
          return data.map((json) => Salary.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          return [Salary.fromJson(data)];
        } else {
          return [];
        }
      }

      // Si l'endpoint n'existe pas (404), utiliser les salaires généraux et filtrer
      if (response.statusCode == 404) {
        final allSalaries = await getSalaries();
        final pendingSalaries =
            allSalaries.where((salary) => salary.status == 'pending').toList();
        return pendingSalaries;
      }

      throw Exception(
        'Erreur lors de la récupération des salaires en attente: ${response.statusCode}',
      );
    } catch (e) {
      // En cas d'erreur, retourner une liste vide au lieu de lever une exception
      return [];
    }
  }

  // Récupérer les employés
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final url = '${AppConfig.baseUrl}/employees-list';
      AppLogger.httpRequest('GET', url, tag: 'SALARY_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'SALARY_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        // Vérifier si le body est complet
        final bodyTrimmed = response.body.trim();
        final isComplete =
            bodyTrimmed.endsWith('}') || bodyTrimmed.endsWith(']');

        if (!isComplete) {
          throw Exception(
            'La réponse du serveur est incomplète (JSON tronqué).',
          );
        }

        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw Exception(
            'Erreur lors du parsing JSON: $e. La réponse du serveur est peut-être mal formatée.',
          );
        }

        if (data['data'] != null) {
          // Le backend peut retourner soit une liste directe, soit un objet paginé
          List<dynamic> dataList;

          if (data['data'] is List) {
            // Format simple : {"success": true, "data": [...]}
            dataList = data['data'] as List;
          } else if (data['data'] is Map && data['data']['data'] != null) {
            // Format paginé : {"success": true, "data": {"current_page": 1, "data": [...]}}
            dataList = data['data']['data'] as List;
          } else {
            AppLogger.warning(
              'Format de données inattendu dans la réponse',
              tag: 'SALARY_SERVICE',
            );
            return [];
          }

          // Transformer les données pour inclure toutes les informations de l'employé
          final employees =
              dataList.map((json) {
                final employee = Map<String, dynamic>.from(json);
                // Construire le nom complet depuis first_name et last_name
                final firstName = employee['first_name'] ?? '';
                final lastName = employee['last_name'] ?? '';
                employee['name'] = '$firstName $lastName'.trim();
                // S'assurer que le salaire est correctement formaté
                if (employee['salary'] != null) {
                  final salary = employee['salary'];
                  if (salary is String) {
                    employee['salary'] = double.tryParse(salary);
                  } else if (salary is num) {
                    employee['salary'] = salary.toDouble();
                  }
                }
                return employee;
              }).toList();

          AppLogger.info(
            '${employees.length} employé(s) récupéré(s)',
            tag: 'SALARY_SERVICE',
          );
          return employees;
        } else {
          AppLogger.warning(
            'Aucune donnée dans la réponse',
            tag: 'SALARY_SERVICE',
          );
          return [];
        }
      } else {
        // Ne jamais retourner de données fictives - lever une exception
        final errorMessage =
            'Erreur lors de la récupération des employés: ${response.statusCode}';
        AppLogger.error(errorMessage, tag: 'SALARY_SERVICE');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la récupération des employés: $e',
        tag: 'SALARY_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne jamais retourner de données fictives - propager l'erreur
      rethrow;
    }
  }

  // Récupérer les composants de salaire
  Future<List<SalaryComponent>> getSalaryComponents() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/salary-components'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => SalaryComponent.fromJson(json)).toList();
      }

      // Si l'endpoint n'existe pas ou a une erreur serveur, retourner des composants par défaut
      if (response.statusCode == 404 || response.statusCode == 500) {
        return [
          SalaryComponent(
            id: 1,
            name: 'Salaire de base',
            type: 'base',
            amount: 0.0,
            description: 'Salaire de base mensuel',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SalaryComponent(
            id: 2,
            name: 'Prime de performance',
            type: 'bonus',
            amount: 0.0,
            description: 'Prime basée sur les performances',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SalaryComponent(
            id: 3,
            name: 'Retenue sécurité sociale',
            type: 'deduction',
            amount: 0.0,
            description: 'Retenue pour la sécurité sociale',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      }

      throw Exception(
        'Erreur lors de la récupération des composants: ${response.statusCode}',
      );
    } catch (e) {
      // En cas d'erreur, retourner des composants par défaut
      return [
        SalaryComponent(
          id: 1,
          name: 'Salaire de base',
          type: 'base',
          amount: 0.0,
          description: 'Salaire de base mensuel',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SalaryComponent(
          id: 2,
          name: 'Prime de performance',
          type: 'bonus',
          amount: 0.0,
          description: 'Prime basée sur les performances',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }
  }

  // Créer un composant de salaire
  Future<SalaryComponent> createSalaryComponent(
    SalaryComponent component,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/salary-components'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(component.toJson()),
      );

      if (response.statusCode == 201) {
        return SalaryComponent.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création du composant: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du composant: $e');
    }
  }

  // Mettre à jour un composant de salaire
  Future<SalaryComponent> updateSalaryComponent(
    SalaryComponent component,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/salary-components/${component.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(component.toJson()),
      );

      if (response.statusCode == 200) {
        return SalaryComponent.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour du composant: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du composant: $e');
    }
  }

  // Supprimer un composant de salaire
  Future<bool> deleteSalaryComponent(int componentId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/salary-components/$componentId'),
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
}
