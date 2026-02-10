import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/models/user_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, authController),
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
      body: Obx(() {
        final user = authController.userAuth.value;
        if (user == null) {
          return const Center(child: Text('Aucune information utilisateur'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec avatar
              _buildHeader(context, user),
              const SizedBox(height: 24),

              // Informations personnelles
              _buildSection(
                title: 'Informations personnelles',
                icon: Icons.person,
                children: [
                  _buildInfoRow(Icons.badge, 'ID', user.id.toString()),
                  if (user.nom != null && user.nom!.isNotEmpty)
                    _buildInfoRow(Icons.person_outline, 'Nom', user.nom!),
                  if (user.prenom != null && user.prenom!.isNotEmpty)
                    _buildInfoRow(Icons.person_outline, 'Prénom', user.prenom!),
                  if (user.email != null && user.email!.isNotEmpty)
                    _buildInfoRow(Icons.email, 'Email', user.email!),
                ],
              ),

              const SizedBox(height: 16),

              // Informations professionnelles
              _buildSection(
                title: 'Informations professionnelles',
                icon: Icons.work,
                children: [
                  _buildInfoRow(
                    Icons.business_center,
                    'Rôle',
                    Roles.getRoleName(user.role ?? 0),
                  ),
                  _buildInfoRow(
                    Icons.circle,
                    'Statut',
                    user.isActive ? 'Actif' : 'Inactif',
                    valueColor: user.isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations système
              if (user.createdAt != null || user.updatedAt != null)
                _buildSection(
                  title: 'Informations système',
                  icon: Icons.info,
                  children: [
                    if (user.createdAt != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date de création',
                        _formatDate(user.createdAt),
                      ),
                    if (user.updatedAt != null)
                      _buildInfoRow(
                        Icons.update,
                        'Dernière mise à jour',
                        _formatDate(user.updatedAt),
                      ),
                  ],
                ),

              const SizedBox(height: 32),

              // Actions
              _buildActionsSection(context, authController),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final String? photoUrl = user is UserModel ? user.photoUrl : (user.avatar?.toString().trim().isNotEmpty == true && user.avatar.toString().startsWith('http') ? user.avatar : null);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _changeProfilePhoto(context, user),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueGrey.shade700,
                    child: photoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => _avatarInitial(user),
                            ),
                          )
                        : _avatarInitial(user),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user.prenom ?? ''} ${user.nom ?? ''}".trim().isNotEmpty
                        ? "${user.prenom ?? ''} ${user.nom ?? ''}".trim()
                        : 'Utilisateur #${user.id}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user.email != null && user.email!.isNotEmpty)
                    Text(
                      user.email!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      Roles.getRoleName(user.role ?? 0),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitial(dynamic user) {
    return Text(
      (user.prenom?.isNotEmpty == true
              ? user.prenom![0]
              : user.nom?.isNotEmpty == true
                  ? user.nom![0]
                  : "?")
          .toUpperCase(),
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context, dynamic user) async {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Get.back();
                await _pickAndUploadPhoto(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Get.back();
                await _pickAndUploadPhoto(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, ImageSource source) async {
    final AuthController authController = Get.find<AuthController>();
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final File file = File(picked.path);
      if (!await file.exists()) return;

      Get.snackbar('Chargement…', 'Mise à jour de la photo en cours…', snackPosition: SnackPosition.BOTTOM);
      final response = await ApiService.updateProfilePhoto(file);
      Get.closeCurrentSnackbar();

      if (response['success'] == true && response['data'] != null) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        authController.userAuth.value = UserModel.fromJson(data);
        await SessionService.saveUser(data);
        Get.snackbar(
          'Photo mise à jour',
          'Votre photo de profil a été enregistrée.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Erreur',
          response['message']?.toString() ?? 'Impossible de mettre à jour la photo.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    AuthController authController,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showChangePasswordDialog(context, authController),
            icon: const Icon(Icons.lock),
            label: const Text('Changer le mot de passe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context, authController),
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 44),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.tryParse(date);
        if (parsed != null) {
          return DateFormat('dd/MM/yyyy à HH:mm').format(parsed);
        }
      } else if (date is DateTime) {
        return DateFormat('dd/MM/yyyy à HH:mm').format(date);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    AuthController authController,
  ) {
    final user = authController.userAuth.value;
    if (user == null) return;

    final nomController = TextEditingController(text: user.nom ?? '');
    final prenomController = TextEditingController(text: user.prenom ?? '');
    final emailController = TextEditingController(text: user.email ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final prenom = prenomController.text.trim();
              final email = emailController.text.trim();
              if (nom.isEmpty || prenom.isEmpty || email.isEmpty) {
                Get.snackbar(
                  'Champs requis',
                  'Veuillez remplir nom, prénom et email.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              if (!GetUtils.isEmail(email)) {
                Get.snackbar(
                  'Email invalide',
                  'Veuillez saisir une adresse email valide.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              try {
                final response = await ApiService.updateUserProfile(
                  nom: nom,
                  prenom: prenom,
                  email: email,
                );
                Get.back();
                if (response['success'] == true && response['data'] != null) {
                  authController.userAuth.value =
                      UserModel.fromJson(Map<String, dynamic>.from(response['data'] as Map));
                  await SessionService.saveUser(
                      Map<String, dynamic>.from(response['data'] as Map));
                  Get.snackbar(
                    'Profil mis à jour',
                    'Vos informations (dont l\'email) ont été enregistrées. Vous recevrez les notifications par mail.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  Get.snackbar(
                    'Erreur',
                    response['message']?.toString() ?? 'Impossible de mettre à jour le profil.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              } catch (e) {
                Get.back();
                Get.snackbar(
                  'Erreur',
                  e.toString().replaceFirst('Exception: ', ''),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthController authController,
  ) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final showCurrentPassword = false.obs;
    final showNewPassword = false.obs;
    final showConfirmPassword = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrentPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () =>
                              showCurrentPassword.value =
                                  !showCurrentPassword.value,
                    ),
                  ),
                  obscureText: !showCurrentPassword.value,
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => showNewPassword.value = !showNewPassword.value,
                    ),
                  ),
                  obscureText: !showNewPassword.value,
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () =>
                              showConfirmPassword.value =
                                  !showConfirmPassword.value,
                    ),
                  ),
                  obscureText: !showConfirmPassword.value,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                Get.snackbar(
                  'Erreur',
                  'Les mots de passe ne correspondent pas',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                Get.snackbar(
                  'Erreur',
                  'Le mot de passe doit contenir au moins 6 caractères',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              // TODO: Implémenter le changement de mot de passe via API
              Get.snackbar(
                'Information',
                'Le changement de mot de passe sera implémenté prochainement',
                snackPosition: SnackPosition.BOTTOM,
              );
              Get.back();
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthController authController,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
