import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/services/favorites_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION AUTH BINDING ===');

    // Initialisation du stockage local
    GetStorage.init();

    // Services essentiels
    Get.put(NotificationService(), permanent: true);
    Get.put(FavoritesService(), permanent: true);
    Get.put(ReportingService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);
    Get.put(InvoiceService(), permanent: true);
    Get.put(PaymentService(), permanent: true);

    // Contrôleur d'authentification
    Get.put(AuthController(), permanent: true);

    // Charger l'utilisateur depuis le stockage local (connexion permanente)
    try {
      final authController = Get.find<AuthController>();
      authController.loadUserFromStorage();
      print('Session utilisateur chargée depuis le stockage local');
    } catch (e) {
      print('Erreur lors du chargement de la session: $e');
    }

    // Démarrer le service de notifications
    try {
      final notificationService = Get.find<NotificationService>();
      notificationService.startNotificationListener();
    } catch (e) {
      print('Erreur démarrage notifications: $e');
    }
  }
}
