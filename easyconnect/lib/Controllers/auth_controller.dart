import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/roles.dart';

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
    print("Starting login process...");
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Erreur", "Veuillez remplir tous les champs");
      return;
    }

    try {
      print("Setting loading state...");
      isLoading.value = true;

      print("Calling API service...");
      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      isLoading.value = false;

      print("Processing response: $response");
      if (response['success'] == true) {
        final data = response['data'];
        print("Processing user data: $data");

        /// Création du modèle utilisateur
        userAuth.value = UserModel.fromJson(data['user']);

        /// Sauvegarde en local
        storage.write("token", data['token']);
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);
        storage.write("user", data['user']); // garde les infos utilisateur

        print(
          "Stored user data - ID: ${userAuth.value?.id}, Role: ${userAuth.value?.role}",
        );

        /// Redirection selon le rôle
        print("Rôle utilisateur: ${userAuth.value?.role}");
        switch (userAuth.value?.role) {
          case Roles.ADMIN:
            print("Redirection ADMIN vers /admin");
            Get.offAllNamed('/admin');
            break;
          case Roles.COMMERCIAL:
            print("Redirection COMMERCIAL vers /commercial");
            Get.offAllNamed('/commercial');
            break;
          case Roles.COMPTABLE:
            print("Redirection COMPTABLE vers /comptable");
            Get.offAllNamed('/comptable');
            break;
          case Roles.PATRON:
            print("Redirection PATRON vers /patron");
            Get.offAllNamed('/patron');
            break;
          case Roles.RH:
            print("Redirection RH vers /rh");
            Get.offAllNamed('/rh');
            break;
          case Roles.TECHNICIEN:
            print("Redirection TECHNICIEN vers /technicien");
            Get.offAllNamed('/technicien');
            break;
          default:
            print("Rôle non reconnu, redirection vers /login");
            Get.offAllNamed('/login');
        }

        Get.snackbar("Succès", "Bienvenue ${userAuth.value?.nom ?? ''} !");
      } else {
        Get.snackbar(
          "Erreur",
          response['message'] ?? "Email ou mot de passe incorrect",
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Erreur", "Une erreur est survenue: $e");
    }
  }

  /// --- Déconnexion
  void logout() {
    storage.erase();
    userAuth.value = null;
    Get.offAllNamed("/login");
  }

  /// --- Charger utilisateur depuis le stockage local (auto-login)
  void loadUserFromStorage() {
    try {
      print("=== CHARGEMENT DE LA SESSION DEPUIS LE STOCKAGE ===");
      final savedUser = storage.read("user");
      final savedToken = storage.read("token");

      print(
        "Données sauvegardées - User: $savedUser, Token: ${savedToken != null ? 'présent' : 'absent'}",
      );

      if (savedUser != null && savedToken != null) {
        userAuth.value = UserModel.fromJson(
          Map<String, dynamic>.from(savedUser),
        );

        // Vérifier et stocker l'ID et le rôle
        storage.write("userId", userAuth.value?.id);
        storage.write("userRole", userAuth.value?.role);

        print(
          "Session restaurée - ID: ${userAuth.value?.id}, Role: ${userAuth.value?.role}, Nom: ${userAuth.value?.nom}",
        );
      } else {
        print("Aucune session sauvegardée trouvée");
        userAuth.value = null;
      }
    } catch (e) {
      print("Erreur lors du chargement de la session: $e");
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
      print("Erreur validation token: $e");
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
