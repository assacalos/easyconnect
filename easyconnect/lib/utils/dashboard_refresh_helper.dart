import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';

/// Helper pour rafraîchir les compteurs des dashboards après une validation/rejet
class DashboardRefreshHelper {
  /// Rafraîchit le compteur spécifique du dashboard patron
  ///
  /// [entityType] peut être: 'client', 'devis', 'bordereau', 'boncommande',
  /// 'facture', 'paiement', 'depense', 'salaire', 'reporting', 'pointage',
  /// 'intervention', 'taxe', 'recruitment', 'contract', 'leave', 'supplier', 'stock'
  static void refreshPatronCounter(String entityType) {
    try {
      if (Get.isRegistered<PatronDashboardController>()) {
        final patronController = Get.find<PatronDashboardController>();
        patronController.refreshSpecificCounter(entityType);
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir le compteur $entityType: $e',
      );
    }
  }

  /// Rafraîchit tous les compteurs du dashboard patron
  static void refreshAllPatronCounters() {
    try {
      if (Get.isRegistered<PatronDashboardController>()) {
        final patronController = Get.find<PatronDashboardController>();
        patronController.refreshPendingCounters();
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir les compteurs: $e',
      );
    }
  }

  /// Rafraîchit les entités en attente du dashboard comptable
  ///
  /// [entityType] peut être: 'facture', 'paiement', 'depense', 'salaire'
  static void refreshComptablePending(String entityType) {
    try {
      if (Get.isRegistered<ComptableDashboardController>()) {
        final comptableController = Get.find<ComptableDashboardController>();
        // Recharger les entités en attente
        comptableController.refreshPendingEntities();
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir les entités en attente du comptable: $e',
      );
    }
  }

  /// Rafraîchit toutes les données du dashboard comptable
  static void refreshComptableDashboard() {
    try {
      if (Get.isRegistered<ComptableDashboardController>()) {
        final comptableController = Get.find<ComptableDashboardController>();
        // Recharger toutes les données
        comptableController.loadData();
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir le dashboard comptable: $e',
      );
    }
  }

  /// Rafraîchit les entités en attente du dashboard technicien
  ///
  /// [entityType] peut être: 'equipment', 'intervention', 'report'
  static void refreshTechnicienPending(String entityType) {
    try {
      if (Get.isRegistered<TechnicienDashboardController>()) {
        final technicienController = Get.find<TechnicienDashboardController>();
        // Recharger les entités en attente de manière asynchrone
        Future.microtask(() async {
          try {
            await technicienController.refreshPendingEntities();
          } catch (e) {
            print(
              '⚠️ [DASHBOARD REFRESH] Erreur lors du rafraîchissement des entités en attente du technicien: $e',
            );
          }
        });
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir les entités en attente du technicien: $e',
      );
    }
  }

  /// Rafraîchit toutes les données du dashboard technicien
  static void refreshTechnicienDashboard() {
    try {
      if (Get.isRegistered<TechnicienDashboardController>()) {
        final technicienController = Get.find<TechnicienDashboardController>();
        // Recharger toutes les données de manière asynchrone
        Future.microtask(() async {
          try {
            await technicienController.loadData();
          } catch (e) {
            print(
              '⚠️ [DASHBOARD REFRESH] Erreur lors du rafraîchissement du dashboard technicien: $e',
            );
          }
        });
      }
    } catch (e) {
      print(
        '⚠️ [DASHBOARD REFRESH] Impossible de rafraîchir le dashboard technicien: $e',
      );
    }
  }
}
