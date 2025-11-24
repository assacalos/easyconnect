import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';

/// Helper pour rafraîchir les compteurs du dashboard patron après une validation/rejet
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
}
