import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class SalaryController {
  static final SalaryController _instance = SalaryController._();
  static SalaryController get to => _instance;
  factory SalaryController() => _instance;
  SalaryController._();

  final SalaryService _salaryService = SalaryService();

  // Variables
  final List<Salary> allSalaries = [];
  final List<Salary> salaries = [];
  final List<Salary> pendingSalaries = [];
  final List<SalaryComponent> salaryComponents = [];
  final List<Map<String, dynamic>> employees = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  SalaryStats? salaryStats;

  // Variables pour le formulaire
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedMonth = 'all';
  int selectedYear = DateTime.now().year;
  Salary? selectedSalary;
  String? _currentStatusFilter;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  // Contrôleurs de formulaire
  final TextEditingController employeeSearchController =
      TextEditingController();
  final TextEditingController baseSalaryController = TextEditingController();
  final TextEditingController bonusController = TextEditingController();
  final TextEditingController deductionsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  int selectedEmployeeId = 0;
  String selectedEmployeeName = '';
  String selectedEmployeeEmail = '';
  String selectedMonthForm = '';
  int selectedYearForm = DateTime.now().year;
  double netSalary = 0.0;
  final List<Map<String, dynamic>> selectedFiles = [];

  void ensureInitialized() {
    loadSalaries();
    loadSalaryStats();
    loadPendingSalaries();
    loadEmployees();
    loadSalaryComponents();
  }

  void dispose() {
    scrollController.dispose();
    employeeSearchController.dispose();
    baseSalaryController.dispose();
    bonusController.dispose();
    deductionsController.dispose();
    notesController.dispose();
  }

  // Charger tous les salaires
  Future<void> loadSalaries({String? statusFilter, int page = 1, bool forceRefresh = false}) async {
    try {
      _currentStatusFilter =
          statusFilter ??
          (selectedStatus == 'all' ? null : selectedStatus);

      final cacheKey = 'salaries_${_currentStatusFilter ?? 'all'}';

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = SalaryService.getCachedSalaires();
          if (hiveList.isNotEmpty) {
            allSalaries.clear();
            allSalaries.addAll(hiveList);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshSalariesFromApi(cacheKey));
            return;
          }
          final cachedSalaries = CacheHelper.get<List<Salary>>(cacheKey);
          if (cachedSalaries != null && cachedSalaries.isNotEmpty) {
            allSalaries.clear();
            allSalaries.addAll(cachedSalaries);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshSalariesFromApi(cacheKey));
            return;
          }
        }
        allSalaries.clear();
        isLoading = true;
      } else if (page > 1) {
        isLoadingMore = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _salaryService.getSalariesPaginated(
          status: _currentStatusFilter,
          month: selectedMonth != 'all' ? selectedMonth : null,
          year: selectedYear,
          search: searchQuery.isNotEmpty ? searchQuery : null,
          page: page,
          perPage: perPage,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          allSalaries.clear();
          allSalaries.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          allSalaries.addAll(paginatedResponse.data);
        }
        applyFilters();

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        final loadedSalaries = await _salaryService.getSalaries(
          status: null,
          month: null,
          year: null,
          search: null,
        );
        if (loadedSalaries.isNotEmpty) {
          if (page == 1) {
            allSalaries.clear();
            allSalaries.addAll(loadedSalaries);
          } else {
            allSalaries.addAll(loadedSalaries);
          }
          applyFilters();
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedSalaries);
          }
        } else if (allSalaries.isEmpty) {
          // Si la liste est vide et qu'on n'a pas reçu de données, vider la liste
          allSalaries.clear();
          salaries.clear();
        }
      }
      // Si allSalaries n'est pas vide, on garde ce qu'on a (mise à jour optimiste)

      // Ne pas afficher de message de succès à chaque chargement
      // Le chargement se fait silencieusement
    } catch (e) {
      print(
        '⚠️ [SALARY_CONTROLLER] Erreur lors du chargement des salaires: $e',
      );

      // Vérifier d'abord si des données sont déjà disponibles (liste ou cache)
      final cacheKey = 'salaries_${_currentStatusFilter ?? 'all'}';
      final cachedSalaries = CacheHelper.get<List<Salary>>(cacheKey);
      final hasDataInList = allSalaries.isNotEmpty || salaries.isNotEmpty;
      final hasDataInCache =
          cachedSalaries != null && cachedSalaries.isNotEmpty;

      // Si des données sont disponibles, les charger et ne pas afficher d'erreur
      if (hasDataInCache && !hasDataInList) {
        // Charger les données du cache si la liste est vide
        allSalaries.clear();
        allSalaries.addAll(cachedSalaries);
        applyFilters();
        print(
          '✅ [SALARY_CONTROLLER] Données chargées depuis le cache (${cachedSalaries.length} salaires)',
        );
      } else if (hasDataInList) {
        // Si la liste contient déjà des données, on garde ce qu'on a
        print(
          '✅ [SALARY_CONTROLLER] Liste des salaires conservée (${allSalaries.length} salaires) malgré l\'erreur de rechargement',
        );
      } else {
        // Vider la liste seulement si aucune donnée n'est disponible
        allSalaries.clear();
        salaries.clear();
      }

      // Ne pas afficher de message d'erreur si des données sont disponibles (liste ou cache)
      // Cela évite d'afficher une erreur après une création réussie ou si des données sont disponibles
      if (!hasDataInList && !hasDataInCache) {
        // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
        final errorString = e.toString().toLowerCase();
        if (!errorString.contains('session expirée') &&
            !errorString.contains('401') &&
            !errorString.contains('unauthorized') &&
            !errorString.contains('impossible de se connecter')) {
          // Ne pas afficher d'erreur pour les erreurs de connexion si des données sont en cache
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les salaires',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  /// Rafraîchit les salaires depuis l'API (page 1) et met à jour la liste/cache si le filtre est inchangé.
  Future<void> _refreshSalariesFromApi(String cacheKey) async {
    try {
      if (_currentStatusFilter !=
          (selectedStatus == 'all' ? null : selectedStatus))
        return;
      final paginatedResponse = await _salaryService.getSalariesPaginated(
        status: _currentStatusFilter,
        month: selectedMonth != 'all' ? selectedMonth : null,
        year: selectedYear,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        page: 1,
        perPage: perPage,
      );
      if (_currentStatusFilter !=
          (selectedStatus == 'all' ? null : selectedStatus))
        return;
      allSalaries.clear();
      allSalaries.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      applyFilters();
      CacheHelper.set(cacheKey, paginatedResponse.data);
      loadSalaryStats().catchError((_) {});
    } catch (_) {}
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadSalaries(
        statusFilter: _currentStatusFilter,
        page: currentPage + 1,
      );
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading && !isLoadingMore) {
      loadSalaries(
        statusFilter: _currentStatusFilter,
        page: currentPage - 1,
      );
    }
  }

  // Charger les salaires en attente
  Future<void> loadPendingSalaries() async {
    try {
      final pending = await _salaryService.getPendingSalaries();
      pendingSalaries.clear();
      pendingSalaries.addAll(pending);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      pendingSalaries.clear();
    }
  }

  // Charger les employés depuis l'endpoint spécifique aux salaires
  // Cet endpoint est accessible au comptable sans avoir besoin de permissions complètes sur les employés
  Future<void> loadEmployees() async {
    try {
      // Utiliser la méthode getEmployees() du SalaryService
      // qui utilise l'endpoint /employees-list spécifique aux salaires
      final employeesList = await _salaryService.getEmployees();

      // Les données sont déjà au format Map<String, dynamic>
      employees.clear();
      employees.addAll(employeesList);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      // L'endpoint peut retourner 403 si le comptable n'a pas accès
      employees.clear();
    }
  }

  // Charger les composants de salaire
  Future<void> loadSalaryComponents() async {
    try {
      final components = await _salaryService.getSalaryComponents();
      salaryComponents.clear();
      salaryComponents.addAll(components);
    } catch (e) {
      // Ne pas bloquer l'application si cette méthode échoue
      salaryComponents.clear();
    }
  }

  // Charger les statistiques
  Future<void> loadSalaryStats() async {
    try {
      final stats = await _salaryService.getSalaryStats();
      salaryStats = stats;
    } catch (e) {}
  }

  // Tester la connectivité à l'API
  Future<bool> testSalaryConnection() async {
    try {
      return await _salaryService.testSalaryConnection();
    } catch (e) {
      return false;
    }
  }

  // Créer un salaire
  Future<bool> createSalary() async {
    try {
      isLoading = true;

      // Validation des champs obligatoires
      if (selectedEmployeeId == 0) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner un employé',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (selectedMonthForm.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner un mois',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (selectedYearForm == 0) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner une année',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
      if (baseSalary <= 0) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Le salaire de base doit être supérieur à 0',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final bonus = double.tryParse(bonusController.text) ?? 0.0;
      final deductions = double.tryParse(deductionsController.text) ?? 0.0;
      final netSalary = baseSalary + bonus - deductions;
      final salary = Salary(
        employeeId: selectedEmployeeId,
        employeeName: selectedEmployeeName,
        employeeEmail: selectedEmployeeEmail,
        baseSalary: baseSalary,
        bonus: bonus,
        deductions: deductions,
        netSalary: netSalary,
        month: selectedMonthForm,
        year: selectedYearForm,
        status: 'pending', // Statut par défaut
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        justificatifs:
            selectedFiles.map((file) => file['path'] as String).toList(),
        // Ne pas inclure createdAt et updatedAt - le serveur les gère
      );

      final createdSalary = await _salaryService.createSalary(salary);

      // Invalider le cache
      CacheHelper.clearByPrefix('salaries_');

      // Ajouter le salaire créé à la liste localement (mise à jour optimiste)
      // S'assurer que le salaire est ajouté avant de naviguer
      if (createdSalary.id != null) {
        allSalaries.add(createdSalary);
        applyFilters(); // Appliquer les filtres pour mettre à jour la liste filtrée
        // Sauvegarder dans le cache pour un affichage instantané
        final cacheKey = 'salaries_${_currentStatusFilter ?? 'all'}';
        CacheHelper.set(cacheKey, allSalaries.toList());

        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName(
            'salary',
            createdSalary,
          ),
          entityId: createdSalary.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'salary',
            createdSalary.id.toString(),
          ),
        );
      }

      // Afficher le message de succès immédiatement
      errorHelperShowSnackbar?.call(
        'Succès',
        'Salaire créé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Rafraîchir les compteurs et recharger en arrière-plan (non-bloquant)
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter('salary');

        // Recharger les données en arrière-plan sans bloquer l'UI
        loadSalaries().catchError((e) {
          print(
            '⚠️ [SALARY_CONTROLLER] Erreur lors du rechargement après création: $e',
          );
          // Ne pas afficher d'erreur à l'utilisateur car la création a réussi
        });

        loadSalaryStats().catchError((e) {
          print(
            '⚠️ [SALARY_CONTROLLER] Erreur lors du rechargement des stats: $e',
          );
        });
      });

      clearForm();
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer le salaire: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Mettre à jour un salaire
  Future<bool> updateSalary(Salary salary) async {
    try {
      isLoading = true;

      final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
      final bonus = double.tryParse(bonusController.text) ?? 0.0;
      final deductions = double.tryParse(deductionsController.text) ?? 0.0;
      final netSalary = baseSalary + bonus - deductions;

      final updatedSalary = Salary(
        id: salary.id,
        employeeId: selectedEmployeeId,
        employeeName: selectedEmployeeName,
        employeeEmail: selectedEmployeeEmail,
        baseSalary: baseSalary,
        bonus: bonus,
        deductions: deductions,
        netSalary: netSalary,
        month: selectedMonthForm,
        year: selectedYearForm,
        status: salary.status,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        createdAt: salary.createdAt,
        updatedAt: DateTime.now(),
        createdBy: salary.createdBy,
        approvedBy: salary.approvedBy,
        approvedAt: salary.approvedAt,
        paidAt: salary.paidAt,
        rejectionReason: salary.rejectionReason,
        justificatifs:
            selectedFiles.isNotEmpty
                ? selectedFiles.map((file) => file['path'] as String).toList()
                : salary.justificatifs,
      );

      await _salaryService.updateSalary(updatedSalary);
      await loadSalaries();
      await loadSalaryStats();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Salaire mis à jour avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      clearForm();
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le salaire: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Approuver un salaire
  Future<void> approveSalary(Salary salary) async {
    try {
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('salaries_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final salaryIndex = salaries.indexWhere((s) => s.id == salary.id);
      final allSalaryIndex = allSalaries.indexWhere((s) => s.id == salary.id);
      final pendingIndex = pendingSalaries.indexWhere((s) => s.id == salary.id);

      if (salaryIndex != -1 || allSalaryIndex != -1) {
        final originalSalary =
            salaryIndex != -1
                ? salaries[salaryIndex]
                : allSalaries[allSalaryIndex];
        // Note: Le modèle Salary a beaucoup de champs, on met juste à jour le statut
        // Pour une mise à jour complète, il faudrait recharger depuis le serveur
        // La mise à jour optimiste sera effectuée après le rechargement
      }

      final success = await _salaryService.approveSalary(
        salary.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('salary');

        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName('salary', salary),
          entityId: salary.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'salary',
            salary.id.toString(),
          ),
          entity: salary,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Salaire approuvé',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
          loadSalaryStats().catchError((e) {});
          loadPendingSalaries().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadSalaries(statusFilter: _currentStatusFilter);
        await loadSalaryStats();
        await loadPendingSalaries();
        throw Exception(
          'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
        );
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
        loadSalaryStats().catchError((e) {});
        loadPendingSalaries().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
        loadSalaryStats().catchError((e) {});
        loadPendingSalaries().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  // Rejeter un salaire
  Future<void> rejectSalary(Salary salary, String reason) async {
    try {
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('salaries_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final salaryIndex = salaries.indexWhere((s) => s.id == salary.id);
      final allSalaryIndex = allSalaries.indexWhere((s) => s.id == salary.id);
      final pendingIndex = pendingSalaries.indexWhere((s) => s.id == salary.id);

      if (salaryIndex != -1 || allSalaryIndex != -1) {
        final originalSalary =
            salaryIndex != -1
                ? salaries[salaryIndex]
                : allSalaries[allSalaryIndex];
        // Note: Le modèle Salary a beaucoup de champs, on met juste à jour le statut
        // Pour une mise à jour complète, il faudrait recharger depuis le serveur
        // La mise à jour optimiste sera effectuée après le rechargement
      }

      final success = await _salaryService.rejectSalary(
        salary.id!,
        reason: reason,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('salary');

        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName('salary', salary),
          entityId: salary.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'salary',
            salary.id.toString(),
          ),
          entity: salary,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Salaire rejeté',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
          loadSalaryStats().catchError((e) {});
          loadPendingSalaries().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadSalaries(statusFilter: _currentStatusFilter);
        await loadSalaryStats();
        await loadPendingSalaries();
        throw Exception(
          'Erreur lors du rejet - La réponse du serveur indique un échec',
        );
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
        loadSalaryStats().catchError((e) {});
        loadPendingSalaries().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadSalaries(statusFilter: _currentStatusFilter).catchError((e) {});
        loadSalaryStats().catchError((e) {});
        loadPendingSalaries().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  // Marquer comme payé
  Future<void> markSalaryAsPaid(Salary salary) async {
    try {
      isLoading = true;

      final success = await _salaryService.markSalaryAsPaid(
        salary.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        await loadSalaries();
        await loadSalaryStats();
        await loadPendingSalaries();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Salaire marqué comme payé',
        );
      } else {
        throw Exception('Erreur lors du paiement');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de marquer le salaire comme payé',
      );
    } finally {
      isLoading = false;
    }
  }

  // Supprimer un salaire
  Future<void> deleteSalary(Salary salary) async {
    try {
      isLoading = true;

      final success = await _salaryService.deleteSalary(salary.id!);
      if (success) {
        salaries.removeWhere((s) => s.id == salary.id);
        await loadSalaryStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Salaire supprimé avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le salaire',
      );
    } finally {
      isLoading = false;
    }
  }

  // Remplir le formulaire avec les données d'un salaire
  void fillForm(Salary salary) {
    selectedEmployeeId = salary.employeeId ?? 0;
    selectedEmployeeName = salary.employeeName ?? '';
    selectedEmployeeEmail = salary.employeeEmail ?? '';
    baseSalaryController.text = salary.baseSalary.toString();
    bonusController.text = salary.bonus.toString();
    deductionsController.text = salary.deductions.toString();
    selectedMonthForm = salary.month ?? '';
    selectedYearForm = salary.year ?? 0;
    notesController.text = salary.notes ?? '';
    selectedSalary = salary;
    // Charger les justificatifs existants
    selectedFiles.clear();
    selectedFiles.addAll(
        salary.justificatifs
            .map(
              (path) => {
                'name': path.split('/').last,
                'path': path,
                'size': 0,
                'type': path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
                'extension': path.split('.').last.toLowerCase(),
              },
            )
            .toList());
  }

  // Mettre à jour le salaire net calculé
  void updateNetSalary() {
    final baseSalary = double.tryParse(baseSalaryController.text) ?? 0.0;
    final bonus = double.tryParse(bonusController.text) ?? 0.0;
    final deductions = double.tryParse(deductionsController.text) ?? 0.0;
    netSalary = baseSalary + bonus - deductions;
  }

  // Vider le formulaire
  void clearForm() {
    selectedEmployeeId = 0;
    selectedEmployeeName = '';
    selectedEmployeeEmail = '';
    baseSalaryController.clear();
    bonusController.clear();
    deductionsController.clear();
    notesController.clear();
    selectedMonthForm = '';
    selectedYearForm = DateTime.now().year;
    selectedSalary = null;
    netSalary = 0.0;
    selectedFiles.clear();
  }

  // Sélectionner des fichiers justificatifs
  Future<void> selectFiles(BuildContext context) async {
    try {
      final String? selectionType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sélectionner des justificatifs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Navigator.of(ctx).pop('file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo / Scanner'),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      if (selectionType == 'file') {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              final fileSize = await file.length();

              if (fileSize > 10 * 1024 * 1024) {
                errorHelperShowSnackbar?.call(
                  'Erreur',
                  'Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)',
                );
                continue;
              }

              String fileType = 'document';
              final extension = platformFile.extension?.toLowerCase() ?? '';
              if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                fileType = 'image';
              } else if (extension == 'pdf') {
                fileType = 'pdf';
              }

              selectedFiles.add({
                'name': platformFile.name,
                'path': platformFile.path!,
                'size': fileSize,
                'type': fileType,
                'extension': extension,
              });
            }
          }

          errorHelperShowSnackbar?.call(
            'Succès',
            '${result.files.length} fichier(s) sélectionné(s)',
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Utiliser CameraService pour une meilleure gestion des permissions
        final cameraService = CameraService();
        File? imageFile;

        try {
          if (selectionType == 'camera') {
            imageFile = await cameraService.takePicture();
          } else {
            imageFile = await cameraService.pickImageFromGallery();
          }

          if (imageFile != null && await imageFile.exists()) {
            // Vérifier que le fichier existe
            if (!await imageFile.exists()) {
              throw Exception('Le fichier sélectionné n\'existe pas');
            }

            final fileSize = await imageFile.length();

            if (fileSize > 10 * 1024 * 1024) {
              errorHelperShowSnackbar?.call(
                'Erreur',
                'Le fichier est trop volumineux (max 10 MB)',
                duration: const Duration(seconds: 3),
              );
              return;
            }

            // Valider l'image
            try {
              await cameraService.validateImage(imageFile);
            } catch (e) {
              errorHelperShowSnackbar?.call(
                'Erreur',
                'Image invalide: $e',
                duration: const Duration(seconds: 3),
              );
              return;
            }

            final fileName = imageFile.path.split('/').last;
            final extension = fileName.split('.').last.toLowerCase();

            selectedFiles.add({
              'name': fileName,
              'path': imageFile.path,
              'size': fileSize,
              'type': 'image',
              'extension': extension,
            });

            errorHelperShowSnackbar?.call(
              'Succès',
              'Fichier sélectionné',
              duration: const Duration(seconds: 2),
            );
          }
        } catch (e) {
          // Gérer les erreurs de permissions et autres erreurs
          String errorMessage = 'Erreur lors de la sélection du fichier';
          if (e.toString().contains('Permission')) {
            errorMessage =
                'Permission refusée. Veuillez autoriser l\'accès à la caméra/photos dans les paramètres de l\'application.';
          } else {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }

          errorHelperShowSnackbar?.call(
            'Erreur',
            errorMessage,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la sélection du fichier: ${e.toString().replaceFirst('Exception: ', '')}',
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Supprimer un fichier de la liste
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Salary> filteredSalaries = List.from(allSalaries);
    // Filtrer par statut
    if (selectedStatus != 'all') {
      filteredSalaries =
          filteredSalaries.where((salary) {
            return salary.status == selectedStatus;
          }).toList();
    }

    // Filtrer par mois
    if (selectedMonth != 'all') {
      filteredSalaries =
          filteredSalaries.where((salary) {
            return salary.month == selectedMonth;
          }).toList();
    }

    // Filtrer par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredSalaries =
          filteredSalaries.where((salary) {
            return (salary.employeeName?.toLowerCase().contains(query) ??
                    false) ||
                (salary.employeeEmail?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    salaries.clear();
    salaries.addAll(filteredSalaries);
  }

  // Rechercher
  void searchSalaries(String query) {
    searchQuery = query;
    applyFilters();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    applyFilters();
  }

  // Filtrer par mois
  void filterByMonth(String month) {
    selectedMonth = month;
    applyFilters();
  }

  // Filtrer par année
  void filterByYear(int year) {
    selectedYear = year;
    applyFilters();
  }

  // Sélectionner un employé
  void selectEmployee(Map<String, dynamic> employee) {
    selectedEmployeeId = employee['id'];
    selectedEmployeeName =
        employee['name'] ??
        '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    selectedEmployeeEmail = employee['email'] ?? '';

    // Pré-remplir le salaire de base avec le salaire de l'employé
    if (employee['salary'] != null) {
      final salary = employee['salary'];
      final salaryValue =
          salary is String
              ? double.tryParse(salary)
              : (salary is num ? salary.toDouble() : null);
      if (salaryValue != null && salaryValue > 0) {
        baseSalaryController.text = salaryValue.toStringAsFixed(0);
        updateNetSalary(); // Mettre à jour le salaire net
      }
    }
  }

  // Sélectionner le mois
  void selectMonth(String month) {
    selectedMonthForm = month;
  }

  // Sélectionner l'année
  void selectYear(int year) {
    selectedYearForm = year;
  }

  // Obtenir les mois
  List<Map<String, dynamic>> get months => [
    {'value': '01', 'label': 'Janvier'},
    {'value': '02', 'label': 'Février'},
    {'value': '03', 'label': 'Mars'},
    {'value': '04', 'label': 'Avril'},
    {'value': '05', 'label': 'Mai'},
    {'value': '06', 'label': 'Juin'},
    {'value': '07', 'label': 'Juillet'},
    {'value': '08', 'label': 'Août'},
    {'value': '09', 'label': 'Septembre'},
    {'value': '10', 'label': 'Octobre'},
    {'value': '11', 'label': 'Novembre'},
    {'value': '12', 'label': 'Décembre'},
  ];

  // Obtenir les années
  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - 2 + index);
  }

  // Vérifier les permissions
  bool get canManageSalaries {
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 3; // Admin, Comptable
  }

  bool get canApproveSalaries {
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewSalaries {
    final userRole = AuthController.to.userAuth?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les salaires par statut
  List<Salary> get salariesByStatus {
    if (selectedStatus == 'all') return salaries;
    return salaries
        .where((salary) => salary.status == selectedStatus)
        .toList();
  }

  // Obtenir les salaires par mois
  List<Salary> get salariesByMonth {
    if (selectedMonth == 'all') return salaries;
    return salaries
        .where((salary) => salary.month == selectedMonth)
        .toList();
  }

  // Obtenir les salaires filtrés
  List<Salary> get filteredSalaries {
    List<Salary> filtered = salaries;

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where((salary) => salary.status == selectedStatus)
              .toList();
    }

    if (selectedMonth != 'all') {
      filtered =
          filtered
              .where((salary) => salary.month == selectedMonth)
              .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (salary) =>
                    (salary.employeeName?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (salary.employeeEmail?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }
}
