import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/utils/roles.dart';

class UserManagementController extends GetxController {
  final UserService _userService = UserService();

  // Observables
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedRole = 'all'.obs;
  final RxBool showActiveOnly = true.obs;

  // Statistiques
  final RxInt totalUsers = 0.obs;
  final RxInt activeUsers = 0.obs;
  final RxInt newUsersThisMonth = 0.obs;

  // Contrôleurs de formulaire
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxInt selectedRoleId = 1.obs;
  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadUserStats();
  }

  @override
  void onClose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Charger tous les utilisateurs
  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final loadedUsers = await _userService.getUsers();
      users.value = loadedUsers;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les utilisateurs: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger les statistiques des utilisateurs
  Future<void> loadUserStats() async {
    try {
      final stats = await _userService.getUserStats();
      totalUsers.value = stats['total'] ?? 0;
      activeUsers.value = stats['active'] ?? 0;
      newUsersThisMonth.value = stats['new_this_month'] ?? 0;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Créer un nouvel utilisateur
  Future<void> createUser() async {
    try {
      isCreating.value = true;

      // Validation des champs
      if (nomController.text.isEmpty ||
          prenomController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez remplir tous les champs',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Validation de l'email
      if (!GetUtils.isEmail(emailController.text)) {
        Get.snackbar(
          'Erreur',
          'Veuillez saisir un email valide',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Validation du mot de passe
      if (passwordController.text.length < 6) {
        Get.snackbar(
          'Erreur',
          'Le mot de passe doit contenir au moins 6 caractères',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final newUser = UserModel(
        id: 0, // Sera généré par le serveur
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        email: emailController.text.trim(),
        role: selectedRoleId.value,
        isActive: true,
      );

      await _userService.createUser(newUser, passwordController.text);

      // Recharger la liste
      await loadUsers();
      await loadUserStats();

      // Réinitialiser le formulaire
      clearForm();

      Get.snackbar(
        'Succès',
        'Utilisateur créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Retourner à la liste
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCreating.value = false;
    }
  }

  /// Mettre à jour un utilisateur
  Future<void> updateUser(UserModel user) async {
    try {
      isLoading.value = true;
      await _userService.updateUser(user);
      await loadUsers();

      Get.snackbar(
        'Succès',
        'Utilisateur mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer un utilisateur
  Future<void> deleteUser(int userId) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        isLoading.value = true;
        final success = await _userService.deleteUser(userId);

        if (success) {
          await loadUsers();
          await loadUserStats();

          Get.snackbar(
            'Succès',
            'Utilisateur supprimé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('Erreur lors de la suppression');
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<void> toggleUserStatus(int userId, bool isActive) async {
    try {
      isLoading.value = true;
      final success = await _userService.toggleUserStatus(userId, isActive);

      if (success) {
        await loadUsers();
        await loadUserStats();

        Get.snackbar(
          'Succès',
          'Statut de l\'utilisateur modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors de la modification du statut');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Filtrer les utilisateurs
  List<UserModel> getFilteredUsers() {
    List<UserModel> filteredUsers = users;

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      filteredUsers =
          filteredUsers.where((user) {
            final fullName =
                '${user.nom ?? ''} ${user.prenom ?? ''}'.toLowerCase();
            final email = user.email?.toLowerCase() ?? '';
            final query = searchQuery.value.toLowerCase();
            return fullName.contains(query) || email.contains(query);
          }).toList();
    }

    // Filtre par rôle
    if (selectedRole.value != 'all') {
      final roleId = _getRoleIdFromName(selectedRole.value);
      filteredUsers =
          filteredUsers.where((user) => user.role == roleId).toList();
    }

    // Filtre par statut actif
    if (showActiveOnly.value) {
      filteredUsers = filteredUsers.where((user) => user.isActive).toList();
    }

    return filteredUsers;
  }

  /// Réinitialiser le formulaire
  void clearForm() {
    nomController.clear();
    prenomController.clear();
    emailController.clear();
    passwordController.clear();
    selectedRoleId.value = 1;
  }

  /// Obtenir le nom du rôle
  String getRoleName(int? role) {
    switch (role) {
      case Roles.ADMIN:
        return 'Administrateur';
      case Roles.COMMERCIAL:
        return 'Commercial';
      case Roles.COMPTABLE:
        return 'Comptable';
      case Roles.RH:
        return 'RH';
      case Roles.TECHNICIEN:
        return 'Technicien';
      case Roles.PATRON:
        return 'Patron';
      default:
        return 'Inconnu';
    }
  }

  /// Obtenir la couleur du rôle
  Color getRoleColor(int? role) {
    switch (role) {
      case Roles.ADMIN:
        return Colors.red;
      case Roles.COMMERCIAL:
        return Colors.blue;
      case Roles.COMPTABLE:
        return Colors.green;
      case Roles.RH:
        return Colors.orange;
      case Roles.TECHNICIEN:
        return Colors.teal;
      case Roles.PATRON:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir l'ID du rôle à partir du nom
  int _getRoleIdFromName(String roleName) {
    switch (roleName) {
      case 'admin':
        return Roles.ADMIN;
      case 'commercial':
        return Roles.COMMERCIAL;
      case 'comptable':
        return Roles.COMPTABLE;
      case 'rh':
        return Roles.RH;
      case 'technicien':
        return Roles.TECHNICIEN;
      case 'patron':
        return Roles.PATRON;
      default:
        return Roles.ADMIN;
    }
  }

  /// Obtenir la liste des rôles pour le dropdown
  List<Map<String, dynamic>> getRolesList() {
    return [
      {'id': Roles.ADMIN, 'name': 'Administrateur'},
      {'id': Roles.COMMERCIAL, 'name': 'Commercial'},
      {'id': Roles.COMPTABLE, 'name': 'Comptable'},
      {'id': Roles.RH, 'name': 'RH'},
      {'id': Roles.TECHNICIEN, 'name': 'Technicien'},
      {'id': Roles.PATRON, 'name': 'Patron'},
    ];
  }
}
