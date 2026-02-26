import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/push_notification_service.dart';
import '../services/websocket_service.dart';
import '../utils/roles.dart';
import '../utils/logger.dart';
import '../utils/cache_helper.dart';

class AuthController extends GetxController {
  /// --- Observables
  var isLoading = false.obs;
  var userAuth = Rxn<UserModel>();
  var showPassword = false.obs;

  /// --- Stockage local
  final storage = GetStorage();

  /// --- Champs du formulaire
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// --- Connexion
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Erreur", "Veuillez remplir tous les champs");
      return;
    }

    // Marquer qu'une connexion est en cours pour éviter les conflits
    SessionService.setLoginInProgress(true);

    try {
      isLoading.value = true;

      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      isLoading.value = false;
      if (response['success'] == true) {
        final data = response['data'];

        // Vérifier que les données nécessaires sont présentes
        if (data == null) {
          SessionService.setLoginInProgress(false);
          Get.snackbar(
            "Erreur",
            "Réponse invalide du serveur: données manquantes",
          );
          return;
        }

        if (data['user'] == null) {
          SessionService.setLoginInProgress(false);
          Get.snackbar(
            "Erreur",
            "Réponse invalide du serveur: informations utilisateur manquantes",
          );
          return;
        }

        if (data['token'] == null || data['token'].toString().isEmpty) {
          SessionService.setLoginInProgress(false);
          Get.snackbar("Erreur", "Réponse invalide du serveur: token manquant");
          return;
        }

        /// Création du modèle utilisateur
        try {
          userAuth.value = UserModel.fromJson(data['user']);
        } catch (e) {
          SessionService.setLoginInProgress(false);
          Get.snackbar(
            "Erreur",
            "Erreur lors du traitement des données utilisateur: $e",
          );
          return;
        }

        /// Sauvegarde en local via SessionService (tokens permanents - n'expirent jamais)
        // Les tokens ne sont invalidés que par le backend (déconnexion manuelle ou révocation)
        final refreshToken = data['refresh_token'] as String?;
        await SessionService.saveToken(
          data['token'],
          refreshToken: refreshToken,
        );
        await SessionService.saveUser(data['user']);

        // Démarrer les vérifications périodiques après connexion réussie
        SessionService.startPeriodicValidation();
        SessionService.startActivityTracking();
        SessionService.updateLastActivity();

        // Attendre un peu pour s'assurer que le storage est bien écrit
        await Future.delayed(const Duration(milliseconds: 300));

        // Vérifier que le token est bien sauvegardé
        final savedToken = SessionService.getTokenSync();
        if (savedToken == null || savedToken.isEmpty) {
          SessionService.setLoginInProgress(false);
          Get.snackbar("Erreur", "Erreur lors de la sauvegarde du token");
          isLoading.value = false;
          return;
        }

        // Stocker le nom de l'utilisateur pour le message de bienvenue
        final userName = userAuth.value?.nom ?? '';

        /// Redirection selon le rôle
        String? route;
        switch (userAuth.value?.role) {
          case Roles.ADMIN:
            route = '/admin';
            break;
          case Roles.COMMERCIAL:
            route = '/commercial';
            break;
          case Roles.COMPTABLE:
            route = '/comptable';
            break;
          case Roles.PATRON:
            route = '/patron';
            break;
          case Roles.RH:
            route = '/rh';
            break;
          case Roles.TECHNICIEN:
            route = '/technicien';
            break;
          default:
            SessionService.setLoginInProgress(false);
            Get.snackbar(
              "Erreur",
              "Rôle utilisateur non reconnu: ${userAuth.value?.role}",
            );
            Get.offAllNamed('/login');
            isLoading.value = false;
            return;
        }

        // Retirer le flag de connexion en cours juste avant la redirection
        SessionService.setLoginInProgress(false);

        // Enregistrer le token FCM après connexion réussie (et retry différé si échec)
        try {
          final pushService = PushNotificationService();
          await pushService.initialize();
          await pushService.registerTokenAfterLogin();
          // Retry après 2 s au cas où le token FCM n'était pas encore prêt
          Future.delayed(const Duration(seconds: 2), () async {
            try {
              await pushService.registerTokenAfterLogin();
            } catch (_) {}
          });
        } catch (e, stackTrace) {
          // Logger l'erreur mais ne pas bloquer la connexion
          AppLogger.error(
            'Erreur lors de l\'enregistrement du token FCM: $e',
            tag: 'AUTH_CONTROLLER',
            error: e,
            stackTrace: stackTrace,
          );
        }

        // Initialiser WebSocket pour les notifications en temps réel
        try {
          await WebSocketService.instance.initialize();
          AppLogger.info(
            'WebSocket initialisé après connexion',
            tag: 'AUTH_CONTROLLER',
          );
        } catch (e, stackTrace) {
          // Logger l'erreur mais ne pas bloquer la connexion
          AppLogger.error(
            'Erreur lors de l\'initialisation WebSocket: $e',
            tag: 'AUTH_CONTROLLER',
            error: e,
            stackTrace: stackTrace,
          );
        }

        // Rediriger vers le dashboard
        await Get.offAllNamed(route);

        // Attendre que la navigation soit complète avant d'afficher le message
        await Future.delayed(const Duration(milliseconds: 500));

        // Afficher le message de bienvenue sur le dashboard
        Get.snackbar(
          "Succès",
          "Bienvenue $userName !",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        SessionService.setLoginInProgress(false);
        final errorMessage =
            response['message'] ?? "Email ou mot de passe incorrect";
        final errors = response['errors'];
        final statusCode = response['statusCode'];

        // Gérer le rate limiting (429)
        if (statusCode == 429) {
          Get.snackbar(
            "Trop de tentatives",
            "Trop de requêtes. Veuillez patienter quelques instants avant de réessayer.",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }

        // Gérer les erreurs serveur (500, 502, 503, 504)
        if (statusCode != null && statusCode >= 500) {
          Get.snackbar(
            "Erreur serveur [$statusCode]",
            "Le serveur rencontre un problème. Vérifiez les logs Laravel sur le serveur.\n\nMessage: $errorMessage",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 8),
            maxWidth: 400,
          );
          return;
        }

        // Gérer les erreurs de validation (422)
        if (errors != null && errors is Map) {
          String validationMessage = errorMessage;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              validationMessage = firstError.first.toString();
            }
          }
          Get.snackbar(
            "Erreur de validation",
            validationMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        } else {
          // Afficher un message plus détaillé
          String displayMessage = errorMessage;
          if (statusCode != null) {
            displayMessage = "[$statusCode] $errorMessage";
          }

          Get.snackbar(
            "Erreur de connexion",
            displayMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      SessionService.setLoginInProgress(false);
      isLoading.value = false;

      String errorMessage = "Une erreur est survenue lors de la connexion";

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage =
            "Impossible de se connecter au serveur. Vérifiez votre connexion internet.";
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('Timeout')) {
        errorMessage =
            "Le serveur ne répond pas. Veuillez réessayer plus tard.";
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Invalid response')) {
        errorMessage =
            "Erreur de communication avec le serveur. Contactez l'administrateur.";
      } else {
        // Afficher le message d'erreur réel pour aider au débogage
        errorMessage = "Erreur: ${e.toString()}";
      }

      Get.snackbar(
        "Erreur",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// --- Déconnexion
  /// [silent] : Si true, ne pas afficher de message de déconnexion
  /// [redirectTo] : Route après déconnexion (ex: '/login', '/welcome'). null = ne pas rediriger
  Future<void> logout({
    bool silent = false,
    String? redirectTo = '/login',
  }) async {
    isLoading.value = true;
    try {
      // Supprimer le token FCM du backend
      try {
        final pushService = PushNotificationService();
        await pushService.unregisterToken();
      } catch (e) {
        // Ignorer les erreurs de suppression du token FCM
      }

      // Retirer le badge de l'icône de l'app (nombre de notifications)
      try {
        await FlutterAppBadger.removeBadge();
      } catch (e) {
        // Ignorer si le launcher ne supporte pas le badge
      }

      // Déconnecter WebSocket
      try {
        WebSocketService.instance.disconnect();
        AppLogger.info('WebSocket déconnecté', tag: 'AUTH_CONTROLLER');
      } catch (e) {
        // Ignorer les erreurs de déconnexion WebSocket
      }

      // Appeler l'API de déconnexion côté serveur (sans attendre si ça timeout)
      try {
        await ApiService.logout().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            return {"success": false, "message": "Timeout"};
          },
        );
      } catch (e) {
        // Ignorer les erreurs de déconnexion serveur
      }
    } catch (e) {
      // Ignorer toute erreur des étapes optionnelles
    }

    // Toujours nettoyer la session (GetStorage + FlutterSecureStorage) pour que la déconnexion soit effective
    try {
      await SessionService.clearSession();
    } catch (e) {
      AppLogger.warning(
        'clearSession a échoué, nettoyage GetStorage de secours',
        tag: 'AUTH_CONTROLLER',
      );
      storage.erase();
      try {
        await SessionService.clearSession();
      } catch (_) {}
    }

    userAuth.value = null;
    CacheHelper.clear();
    _cleanupControllers();

    if (redirectTo != null && redirectTo.isNotEmpty) {
      Get.offAllNamed(redirectTo);
    }
    isLoading.value = false;
  }

  /// Nettoyer tous les contrôleurs pour éviter les requêtes en cours
  void _cleanupControllers() {
    try {
      // Annuler tous les timers et listeners actifs
      // Les contrôleurs individuels devraient gérer leur propre nettoyage dans onClose
    } catch (e) {
      // Ignorer les erreurs de nettoyage
    }
  }

  /// --- Charger utilisateur depuis le stockage local (auto-login)
  void loadUserFromStorage() {
    try {
      final savedUser = SessionService.getUser();
      final savedToken = SessionService.getTokenSync();
      if (savedUser != null && savedToken != null && savedToken.isNotEmpty) {
        userAuth.value = UserModel.fromJson(
          Map<String, dynamic>.from(savedUser),
        );
      } else {
        userAuth.value = null;
      }
    } catch (e) {
      userAuth.value = null;
    }
  }

  /// --- Vérifier la validité du token (optionnel)
  Future<bool> validateToken() async {
    try {
      return await SessionService.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Rafraîchit les données utilisateur depuis le backend
  /// Utile pour détecter les changements de rôle, désactivation, etc.
  Future<void> refreshUserData() async {
    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      // Appeler un endpoint pour récupérer les données utilisateur actualisées
      final response = await ApiService.getUser();

      if (response['success'] == true && response['data'] != null) {
        // Mettre à jour les données utilisateur
        userAuth.value = UserModel.fromJson(response['data']);
        await SessionService.saveUser(response['data']);

        AppLogger.info(
          'Données utilisateur rafraîchies avec succès',
          tag: 'AUTH_CONTROLLER',
        );
      }
    } catch (e) {
      // Si erreur 401, AuthErrorHandler déconnectera automatiquement
      // Sinon, ignorer (problème réseau temporaire)
      AppLogger.debug(
        'Erreur lors du rafraîchissement des données utilisateur: $e',
        tag: 'AUTH_CONTROLLER',
      );
    }
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }
}
