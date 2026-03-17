import 'package:flutter/material.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/error_helper.dart';

class UserManagementController {
  static final UserManagementController _instance = UserManagementController._();
  static UserManagementController get to => _instance;
  factory UserManagementController() => _instance;
  UserManagementController._();

  final UserService _userService = UserService();

  final List<UserModel> users = [];
  bool isLoading = false;
  String searchQuery = '';
  String selectedRole = 'all';
  bool showActiveOnly = true;

  int totalUsers = 0;
  int activeUsers = 0;
  int newUsersThisMonth = 0;

  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  int selectedRoleId = 1;
  bool isCreating = false;

  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> loadUsers() async {
    try {
      isLoading = true;
      final loadedUsers = await _userService.getUsers();
      users.clear();
      users.addAll(loadedUsers);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized') &&
          users.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Impossible de charger les utilisateurs: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadUserStats() async {
    try {
      final stats = await _userService.getUserStats();
      totalUsers = stats['total'] ?? 0;
      activeUsers = stats['active'] ?? 0;
      newUsersThisMonth = stats['new_this_month'] ?? 0;
    } catch (e) {}
  }

  static bool _isEmail(String s) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(s);
  }

  Future<bool> createUser() async {
    try {
      isCreating = true;

      if (nomController.text.isEmpty ||
          prenomController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez remplir tous les champs',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (!_isEmail(emailController.text)) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez saisir un email valide',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      if (passwordController.text.length < 6) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Le mot de passe doit contenir au moins 6 caractères',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final newUser = UserModel(
        id: 0,
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim(),
        email: emailController.text.trim(),
        role: selectedRoleId,
        isActive: true,
      );

      await _userService.createUser(newUser, passwordController.text);

      await loadUsers();
      await loadUserStats();
      clearForm();

      ErrorHelper.showSuccess('Utilisateur créé avec succès');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer l\'utilisateur: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isCreating = false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      isLoading = true;
      await _userService.updateUser(user);
      await loadUsers();

      ErrorHelper.showSuccess('Utilisateur mis à jour avec succès');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour l\'utilisateur: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteUser(BuildContext context, int userId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        isLoading = true;
        final success = await _userService.deleteUser(userId);

        if (success) {
          await loadUsers();
          await loadUserStats();
          ErrorHelper.showSuccess('Utilisateur supprimé avec succès');
        } else {
          throw Exception('Erreur lors de la suppression');
        }
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer l\'utilisateur: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> toggleUserStatus(int userId, bool isActive) async {
    try {
      isLoading = true;
      final success = await _userService.toggleUserStatus(userId, isActive);

      if (success) {
        await loadUsers();
        await loadUserStats();
        ErrorHelper.showSuccess('Statut de l\'utilisateur modifié avec succès');
      } else {
        throw Exception('Erreur lors de la modification du statut');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de modifier le statut: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
    }
  }

  List<UserModel> getFilteredUsers() {
    List<UserModel> filteredUsers = List.from(users);

    if (searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final fullName = '${user.nom ?? ''} ${user.prenom ?? ''}'.toLowerCase();
        final email = user.email?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return fullName.contains(query) || email.contains(query);
      }).toList();
    }

    if (selectedRole != 'all') {
      final roleId = _getRoleIdFromName(selectedRole);
      filteredUsers = filteredUsers.where((user) => user.role == roleId).toList();
    }

    if (showActiveOnly) {
      filteredUsers = filteredUsers.where((user) => user.isActive).toList();
    }

    return filteredUsers;
  }

  void clearForm() {
    nomController.clear();
    prenomController.clear();
    emailController.clear();
    passwordController.clear();
    selectedRoleId = 1;
  }

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
