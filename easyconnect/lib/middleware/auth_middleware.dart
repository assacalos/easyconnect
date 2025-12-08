import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/services/session_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Si on est sur la page de login ou splash, laisser passer
      if (route == '/login' || route == '/splash') {
        return null;
      }

      // Utiliser SessionService pour vérifier l'authentification de manière centralisée
      // isValidSession prend en compte les connexions en cours pour éviter les conflits
      final isValid = SessionService.isValidSession(allowLoginInProgress: true);

      if (!isValid) {
        // Si la session n'est pas valide et qu'aucune connexion n'est en cours, rediriger
        if (!SessionService.isLoginInProgress()) {
          return const RouteSettings(name: '/login');
        }
        // Si une connexion est en cours, laisser passer pour éviter d'interrompre le processus
        return null;
      }

      // Récupérer le rôle utilisateur
      final authController = SessionService.getAuthController();
      int? userRole;

      if (authController != null && authController.userAuth.value != null) {
        // Utiliser le contrôleur si disponible (priorité)
        userRole = authController.userAuth.value?.role;
      } else {
        // Vérifier via SessionService si le contrôleur n'est pas encore initialisé
        userRole = SessionService.getUserRole();
      }

      // Si le rôle n'est pas disponible, rediriger vers login
      if (userRole == null) {
        return const RouteSettings(name: '/login');
      }

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
      // Si une erreur survient, rediriger vers login pour sécurité
      return const RouteSettings(name: '/login');
    }
  }
}
