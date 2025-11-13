import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Essayer de récupérer l'AuthController
      final authController = Get.find<AuthController>();

      // Si l'utilisateur n'est pas connecté, rediriger vers la page de connexion
      if (authController.userAuth.value == null) {
        return const RouteSettings(name: '/login');
      }

      // Vérifier les permissions selon la route
      final userRole = authController.userAuth.value?.role;
      if (userRole == null) return const RouteSettings(name: '/login');

      // L'ADMIN peut accéder à toutes les pages
      if (userRole == Roles.ADMIN) {
        return null;
      }

      // Définir les permissions requises pour chaque route
      switch (route) {
        case '/rh':
          if (userRole != Roles.RH) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
        case '/commercial':
          if (userRole != Roles.COMMERCIAL) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
        case '/comptable':
          if (userRole != Roles.COMPTABLE) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
        case '/patron':
          if (userRole != Roles.PATRON) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
        case '/technicien':
          if (userRole != Roles.TECHNICIEN) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
        case '/admin/users':
          // Le patron et RH peuvent voir la liste des utilisateurs (employés)
          if (userRole != Roles.ADMIN &&
              userRole != Roles.PATRON &&
              userRole != Roles.RH) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
      }

      // Si tout est OK, laisser passer
      return null;
    } catch (e) {
      // Si l'AuthController n'est pas trouvé, rediriger vers login
      print('AuthController non trouvé dans le middleware: $e');
      return const RouteSettings(name: '/login');
    }
  }
}
