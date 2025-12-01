import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/roles.dart';
import '../utils/app_config.dart';

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

    try {
      isLoading.value = true;

      print('🔐 DÉBUT DE LA CONNEXION');
      print('Email: ${emailController.text.trim()}');
      print('URL API: ${AppConfig.baseUrl}');

      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      print('📥 RÉPONSE REÇUE: $response');

      isLoading.value = false;
      if (response['success'] == true) {
        final data = response['data'];

        // Vérifier que les données nécessaires sont présentes
        if (data == null) {
          Get.snackbar(
            "Erreur",
            "Réponse invalide du serveur: données manquantes",
          );
          return;
        }

        if (data['user'] == null) {
          Get.snackbar(
            "Erreur",
            "Réponse invalide du serveur: informations utilisateur manquantes",
          );
          return;
        }

        if (data['token'] == null || data['token'].toString().isEmpty) {
          Get.snackbar("Erreur", "Réponse invalide du serveur: token manquant");
          return;
        }

        /// Création du modèle utilisateur
        try {
          userAuth.value = UserModel.fromJson(data['user']);
        } catch (e) {
          Get.snackbar(
            "Erreur",
            "Erreur lors du traitement des données utilisateur: $e",
          );
          return;
        }

        /// Sauvegarde en local
        storage.write("token", data['token']);
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);
        storage.write("user", data['user']); // garde les infos utilisateur

        // Attendre un peu pour s'assurer que le storage est bien écrit
        await Future.delayed(const Duration(milliseconds: 500));

        // Vérifier que le token est bien sauvegardé
        final savedToken = storage.read("token");
        if (savedToken == null || savedToken.toString().isEmpty) {
          Get.snackbar("Erreur", "Erreur lors de la sauvegarde du token");
          isLoading.value = false;
          return;
        }

        // S'assurer que userAuth est bien défini avant la redirection
        print(
          '🔐 [AUTH] Token sauvegardé, userAuth.value: ${userAuth.value?.id}, rôle: ${userAuth.value?.role}',
        );

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
            Get.snackbar(
              "Erreur",
              "Rôle utilisateur non reconnu: ${userAuth.value?.role}",
            );
            Get.offAllNamed('/login');
            isLoading.value = false;
            return;
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
        print('❌ ÉCHEC DE CONNEXION');
        print('Réponse complète: $response');

        final errorMessage =
            response['message'] ?? "Email ou mot de passe incorrect";
        final errors = response['errors'];
        final statusCode = response['statusCode'];

        print('Message d\'erreur: $errorMessage');
        print('Erreurs: $errors');
        print('Status code: $statusCode');

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
    } catch (e, stackTrace) {
      isLoading.value = false;

      // Logger l'erreur complète pour le débogage
      print('❌ ERREUR DE CONNEXION:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: $stackTrace');

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
  Future<void> logout() async {
    try {
      // Marquer que l'utilisateur est en train de se déconnecter
      // Cela empêchera les autres contrôleurs de charger des données
      isLoading.value = true;

      // Appeler l'API de déconnexion côté serveur (sans attendre si ça timeout)
      try {
        await ApiService.logout().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            // Ignorer le timeout, on continue quand même la déconnexion
            print(
              '⚠️ [AUTH] Timeout lors de la déconnexion serveur, continuation...',
            );
            return {"success": false, "message": "Timeout"};
          },
        );
      } catch (e) {
        // Ignorer les erreurs de déconnexion serveur
        print('⚠️ [AUTH] Erreur lors de la déconnexion serveur: $e');
      }

      // Nettoyer le stockage local
      storage.erase();
      userAuth.value = null;

      // Nettoyer tous les contrôleurs enregistrés pour éviter les requêtes en cours
      _cleanupControllers();

      // Rediriger vers la page de login
      Get.offAllNamed("/login");
    } catch (e) {
      // En cas d'erreur, forcer quand même la déconnexion
      print('❌ [AUTH] Erreur lors de la déconnexion: $e');
      storage.erase();
      userAuth.value = null;
      Get.offAllNamed("/login");
    } finally {
      isLoading.value = false;
    }
  }

  /// Nettoyer tous les contrôleurs pour éviter les requêtes en cours
  void _cleanupControllers() {
    try {
      // Annuler tous les timers et listeners actifs
      // Les contrôleurs individuels devraient gérer leur propre nettoyage dans onClose

      // Forcer le nettoyage du cache si nécessaire
      // CacheHelper.clear(); // Décommenter si nécessaire
    } catch (e) {
      print('⚠️ [AUTH] Erreur lors du nettoyage des contrôleurs: $e');
    }
  }

  /// --- Charger utilisateur depuis le stockage local (auto-login)
  void loadUserFromStorage() {
    try {
      final savedUser = storage.read("user");
      final savedToken = storage.read("token");
      if (savedUser != null && savedToken != null) {
        userAuth.value = UserModel.fromJson(
          Map<String, dynamic>.from(savedUser),
        );

        // Vérifier et stocker l'ID et le rôle
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);
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
      final token = storage.read("token");
      if (token == null) return false;

      // Ici vous pouvez ajouter une vérification côté serveur
      // Pour l'instant, on considère que le token est valide s'il existe
      return true;
    } catch (e) {
      return false;
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
