import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/services/favorites_service.dart';

class AppBindings extends Bindings {
  @override
  /* void dependencies() {
    print('=== INITIALISATION DES BINDINGS ===');

    // Initialisation du stockage local
    _initializeStorage();

    // Initialisation des contrôleurs principaux
    _initializeMainControllers();

    // Initialisation des services de base
    _initializeServices();

    // Initialisation des contrôleurs de dashboard
    _initializeDashboardControllers();

    // Démarrage des services
    _startServices();
  } */
  void dependencies() {
    Get.put(AuthController());
    Get.put(DevisController());
    Get.put(BordereauController());
    Get.put(BonCommandeController());
    Get.put(NotificationService(), permanent: true);
    Get.put(FavoritesService(), permanent: true);

    Get.put(ClientController());
    Get.put(PatronDashboardController());
    Get.put(CommercialDashboardController());
    Get.put(ComptableDashboardController());
    Get.put(RhDashboardController());
    Get.put(TechnicienDashboardController());
  }
}
