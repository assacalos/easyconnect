import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class AuthMiddleware extends GetMiddleware {
  final storage = GetStorage();

  @override
  RouteSettings? redirect(String? route) {
    try {
      // Essayer de récupérer l'AuthController s'il est enregistré
      AuthController? authController;
      if (Get.isRegistered<AuthController>()) {
        authController = Get.find<AuthController>();
      }

      // Vérifier l'authentification via le contrôleur ou directement via le stockage
      bool isAuthenticated = false;
      int? userRole;

      if (authController != null && authController.userAuth.value != null) {
        // Utiliser le contrôleur si disponible
        isAuthenticated = true;
        userRole = authController.userAuth.value?.role;
        print(
          '🔒 [AUTH_MIDDLEWARE] Authentification via contrôleur - Rôle: $userRole',
        );
      } else {
        // Vérifier directement dans le stockage si le contrôleur n'est pas encore initialisé
        final token = storage.read('token');
        final savedUser = storage.read('user');
        final savedRole = storage.read('userRole');

        print(
          '🔒 [AUTH_MIDDLEWARE] Vérification storage - Token: ${token != null ? "présent" : "absent"}, User: ${savedUser != null ? "présent" : "absent"}',
        );

        if (token != null && savedUser != null) {
          isAuthenticated = true;
          userRole =
              savedRole is int
                  ? savedRole
                  : (savedRole is String ? int.tryParse(savedRole) : null);
          print(
            '🔒 [AUTH_MIDDLEWARE] Authentification via storage - Rôle: $userRole',
          );
        }
      }

      // Si l'utilisateur n'est pas connecté, rediriger vers la page de connexion
      // Mais seulement si on n'est pas déjà sur la page de login ou splash
      if ((!isAuthenticated || userRole == null) &&
          route != '/login' &&
          route != '/splash') {
        print(
          '🔒 [AUTH_MIDDLEWARE] Utilisateur non authentifié, redirection vers /login',
        );
        return const RouteSettings(name: '/login');
      }

      print(
        '🔒 [AUTH_MIDDLEWARE] Utilisateur authentifié avec le rôle: $userRole',
      );

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
