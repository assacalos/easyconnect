import 'package:easyconnect/Views/Commercial/client_details_page.dart';
import 'package:easyconnect/Views/Commercial/client_list_page.dart';
import 'package:easyconnect/Views/Commercial/devis_list_page.dart';
import 'package:easyconnect/Views/Commercial/devis_form_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_list_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_list_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_form_page.dart';
import 'package:easyconnect/Views/Patron/client_validation_page.dart';
import 'package:easyconnect/Views/Patron/bordereau_validation_page.dart';
import 'package:easyconnect/Views/Patron/bon_commande_validation_page.dart';
import 'package:easyconnect/Views/Patron/patron_dashboard_v2.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Views/Auth/login_page.dart';
import 'package:easyconnect/Views/Auth/unauthorized_page.dart';
import 'package:easyconnect/Views/Commercial/commercial_dashboard.dart';
import 'package:easyconnect/Views/Comptable/comptable_dashboard.dart';
import 'package:easyconnect/Views/Rh/rh_dashboard.dart';
import 'package:easyconnect/Views/Technicien/technicien_dashboard.dart';
import 'package:easyconnect/Views/Components/splash_screen.dart';
import 'package:easyconnect/middleware/auth_middleware.dart';
import 'package:easyconnect/bindings/auth_binding.dart';
import 'package:easyconnect/bindings/commercial_binding.dart';
import 'package:easyconnect/bindings/patron_binding.dart';
import 'package:easyconnect/bindings/comptable_binding.dart';
import 'package:easyconnect/bindings/rh_binding.dart';
import 'package:easyconnect/bindings/technicien_binding.dart';
import 'package:easyconnect/Views/Components/reporting_list.dart';
import 'package:easyconnect/Views/Components/reporting_form.dart';
import 'package:easyconnect/Views/Components/attendance_page.dart';
import 'package:easyconnect/Views/Components/invoice_list.dart';
import 'package:easyconnect/Views/Components/invoice_form.dart';
import 'package:easyconnect/Views/Components/payment_list.dart';
import 'package:easyconnect/Views/Components/payment_form.dart';
import 'package:easyconnect/Views/Components/payment_detail.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => LoginPage()),
    GetPage(name: '/unauthorized', page: () => UnauthorizedPage()),
    GetPage(
      name: '/commercial',
      page: () => CommercialDashboard(),
      binding: CommercialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/comptable',
      page: () => ComptableDashboard(),
      binding: ComptableBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/patron',
      page: () => PatronDashboard(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/rh',
      page: () => RhDashboard(),
      binding: RhBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/technicien',
      page: () => TechnicienDashboard(),
      binding: TechnicienBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients',
      page: () => ClientsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients/validation',
      page: () => ClientValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients/:id',
      page:
          () => ClientDetailsPage(
            clientId: int.parse(Get.parameters['id'] ?? '0'),
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis',
      page: () => DevisListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/new',
      page: () => DevisFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/:id/edit',
      page:
          () => DevisFormPage(
            isEditing: true,
            devisId: int.parse(Get.parameters['id'] ?? '0'),
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux',
      page: () => BordereauListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/new',
      page: () => BordereauFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/:id/edit',
      page:
          () => BordereauFormPage(
            isEditing: true,
            bordereauId: int.parse(Get.parameters['id'] ?? '0'),
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/validation',
      page: () => BordereauValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes',
      page: () => BonCommandeListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/new',
      page: () => BonCommandeFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/:id/edit',
      page:
          () => BonCommandeFormPage(
            isEditing: true,
            bonCommandeId: int.parse(Get.parameters['id'] ?? '0'),
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/validation',
      page: () => BonCommandeValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    // Routes de reporting
    GetPage(
      name: '/reporting',
      page: () => const ReportingList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/reporting/new',
      page: () => const ReportingForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/attendance',
      page: () => const AttendancePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/invoices',
      page: () => const InvoiceList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/invoices/new',
      page: () => const InvoiceForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments',
      page: () => const PaymentList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments/new',
      page: () => const PaymentForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments/detail',
      page: () => PaymentDetail(paymentId: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
  ];

  static String getInitialRoute(int? userRole) {
    // Si pas de rôle ou utilisateur non connecté, aller à la page de connexion
    if (userRole == null) return '/login';

    // Rediriger vers la page appropriée selon le rôle
    switch (userRole) {
      case 1: // Admin
        return '/patron'; // Vue globale
      case 2: // Commercial
        return '/commercial';
      case 3: // Comptable
        return '/comptable';
      case 4: // Patron
        return '/patron';
      case 5: // RH
        return '/rh';
      case 6: // Technicien
        return '/technicien';
      default:
        return '/login';
    }
  }
}
