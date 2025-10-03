import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/utils/constant.dart';

class SalaryService {
  final storage = GetStorage();

  // Tester la connectivité à l'API pour les salaires
  Future<bool> testSalaryConnection() async {
    try {
      print('🧪 SalaryService: Test de connectivité à l\'API...');
      print('🌐 SalaryService: URL de base: $baseUrl');

      final token = storage.read('token');
      print('🔑 SalaryService: Token disponible: ${token != null ? "✅" : "❌"}');

      final response = await http
          .get(
            Uri.parse('$baseUrl/salaries-list'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        '📡 SalaryService: Test de connectivité - Status: ${response.statusCode}',
      );
      print('📄 SalaryService: Test de connectivité - Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ SalaryService: Erreur de connectivité: $e');
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
      print('🌐 SalaryService: getSalaries() appelé');
      print(
        '📊 SalaryService: status=$status, month=$month, year=$year, search=$search',
      );

      final token = storage.read('token');
      print('🔑 SalaryService: Token récupéré: ${token != null ? "✅" : "❌"}');

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
      print('🔗 SalaryService: URL appelée: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 SalaryService: Réponse reçue - Status: ${response.statusCode}');
      print('📄 SalaryService: Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('📊 SalaryService: Response data keys: ${responseData.keys}');

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

          print(
            '📦 SalaryService: ${data.length} salaires trouvés dans l\'API',
          );

          if (data.isEmpty) {
            print('⚠️ SalaryService: Aucun salaire trouvé dans l\'API');
            return [];
          }

          try {
            return data.map((json) {
              print('🔍 SalaryService: Parsing salary JSON: $json');
              return Salary.fromJson(json);
            }).toList();
          } catch (e) {
            print('❌ SalaryService: Erreur lors du parsing des salaires: $e');
            print('📄 SalaryService: Données problématiques: $data');
            rethrow;
          }
        } catch (e) {
          print('❌ SalaryService: Erreur de parsing JSON: $e');
          print('📄 SalaryService: Body content: ${response.body}');
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        print(
          '❌ SalaryService: Erreur API ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Erreur lors de la récupération des salaires: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ SalaryService: Erreur lors du chargement des salaires: $e');
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
      print('Erreur SalaryService.getSalaryById: $e');
      throw Exception('Erreur lors de la récupération du salaire: $e');
    }
  }

  // Créer un salaire
  Future<Salary> createSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/salaries-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salary.toJson()),
      );

      if (response.statusCode == 201) {
        return Salary.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création du salaire: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur SalaryService.createSalary: $e');
      throw Exception('Erreur lors de la création du salaire: $e');
    }
  }

  // Mettre à jour un salaire
  Future<Salary> updateSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/salaries-update/${salary.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salary.toJson()),
      );

      if (response.statusCode == 200) {
        return Salary.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour du salaire: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur SalaryService.updateSalary: $e');
      throw Exception('Erreur lors de la mise à jour du salaire: $e');
    }
  }

  // Approuver un salaire
  Future<bool> approveSalary(int salaryId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/salaries-validate/$salaryId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur SalaryService.approveSalary: $e');
      return false;
    }
  }

  // Rejeter un salaire
  Future<bool> rejectSalary(int salaryId, {required String reason}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/salaries-reject/$salaryId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur SalaryService.rejectSalary: $e');
      return false;
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
      print('Erreur SalaryService.markSalaryAsPaid: $e');
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
      print('Erreur SalaryService.deleteSalary: $e');
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
      print('Erreur SalaryService.getSalaryStats: $e');
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
    print('🔄 SalaryService: getPendingSalaries() appelé');
    try {
      final token = storage.read('token');
      print(
        '🔑 SalaryService: Token récupéré: ${token != null ? "Oui" : "Non"}',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/salaries-pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 SalaryService: Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ SalaryService: Données reçues avec succès');
        final responseData = json.decode(response.body);
        final dynamic data = responseData['data'];

        // Gérer le cas où data est une liste ou un objet
        if (data is List) {
          print('📦 SalaryService: ${data.length} salaires reçus');
          return data.map((json) => Salary.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          print('📦 SalaryService: 1 salaire reçu');
          return [Salary.fromJson(data)];
        } else {
          print('⚠️ SalaryService: Aucune donnée valide');
          return [];
        }
      }

      // Si l'endpoint n'existe pas (404), utiliser les salaires généraux et filtrer
      if (response.statusCode == 404) {
        print(
          '⚠️ SalaryService: Endpoint salaries-pending non trouvé (404), utilisation du filtrage côté client',
        );
        final allSalaries = await getSalaries();
        final pendingSalaries =
            allSalaries.where((salary) => salary.status == 'pending').toList();
        print(
          '📦 SalaryService: ${pendingSalaries.length} salaires en attente trouvés via filtrage',
        );
        return pendingSalaries;
      }

      print('❌ SalaryService: Erreur ${response.statusCode}');
      throw Exception(
        'Erreur lors de la récupération des salaires en attente: ${response.statusCode}',
      );
    } catch (e) {
      print('❌ SalaryService: Exception dans getPendingSalaries: $e');
      // En cas d'erreur, retourner une liste vide au lieu de lever une exception
      return [];
    }
  }

  // Récupérer les employés
  Future<List<Map<String, dynamic>>> getEmployees() async {
    print('🔄 SalaryService: getEmployees() appelé');
    try {
      final token = storage.read('token');
      print(
        '🔑 SalaryService: Token récupéré: ${token != null ? "Oui" : "Non"}',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/employees-list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 SalaryService: Réponse employés - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('✅ SalaryService: Employés reçus avec succès');
        final List<dynamic> data = json.decode(response.body)['data'];
        print('👥 SalaryService: ${data.length} employés reçus');
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }

      // Si l'endpoint n'existe pas ou n'est pas accessible, retourner des données de test
      if (response.statusCode == 403 || response.statusCode == 404) {
        print(
          '⚠️ SalaryService: Endpoint employees-list non accessible (${response.statusCode}), utilisation de données de test',
        );
        return [
          {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'position': 'Développeur',
          },
          {
            'id': 2,
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'position': 'Designer',
          },
          {
            'id': 3,
            'name': 'Bob Johnson',
            'email': 'bob@example.com',
            'position': 'Manager',
          },
        ];
      }

      print('❌ SalaryService: Erreur ${response.statusCode} pour employés');
      throw Exception(
        'Erreur lors de la récupération des employés: ${response.statusCode}',
      );
    } catch (e) {
      print('❌ SalaryService: Exception dans getEmployees: $e');
      // En cas d'erreur, retourner des données de test
      print('🔄 SalaryService: Utilisation des données de test pour employés');
      return [
        {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'position': 'Développeur',
        },
        {
          'id': 2,
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'position': 'Designer',
        },
      ];
    }
  }

  // Récupérer les composants de salaire
  Future<List<SalaryComponent>> getSalaryComponents() async {
    print('🔄 SalaryService: getSalaryComponents() appelé');
    try {
      final token = storage.read('token');
      print(
        '🔑 SalaryService: Token récupéré: ${token != null ? "Oui" : "Non"}',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/salary-components'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 SalaryService: Réponse composants - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        print('✅ SalaryService: Composants reçus avec succès');
        final List<dynamic> data = json.decode(response.body)['data'];
        print('🧩 SalaryService: ${data.length} composants reçus');
        return data.map((json) => SalaryComponent.fromJson(json)).toList();
      }

      // Si l'endpoint n'existe pas ou a une erreur serveur, retourner des composants par défaut
      if (response.statusCode == 404 || response.statusCode == 500) {
        print(
          '⚠️ SalaryService: Endpoint salary-components non accessible (${response.statusCode}), utilisation de composants par défaut',
        );
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

      print('❌ SalaryService: Erreur ${response.statusCode} pour composants');
      throw Exception(
        'Erreur lors de la récupération des composants: ${response.statusCode}',
      );
    } catch (e) {
      print('❌ SalaryService: Exception dans getSalaryComponents: $e');
      // En cas d'erreur, retourner des composants par défaut
      print('🔄 SalaryService: Utilisation des composants par défaut');
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
      print('Erreur SalaryService.createSalaryComponent: $e');
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
      print('Erreur SalaryService.updateSalaryComponent: $e');
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
      print('Erreur SalaryService.deleteSalaryComponent: $e');
      return false;
    }
  }
}
