import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/user_management_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class UserFormPage extends StatelessWidget {
  final bool isEditing;
  final int? userId;

  const UserFormPage({super.key, this.isEditing = false, this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                if (userId != null) {
                  controller.deleteUser(userId!);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing
                        ? 'Modifier l\'utilisateur'
                        : 'Créer un nouvel utilisateur',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Modifiez les informations de l\'utilisateur'
                        : 'Remplissez le formulaire pour créer un nouvel utilisateur',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulaire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nom
                    TextFormField(
                      controller: controller.nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        hintText: 'Entrez le nom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Prénom
                    TextFormField(
                      controller: controller.prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        hintText: 'Entrez le prénom',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prénom est requis';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: controller.emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'Entrez l\'email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Veuillez saisir un email valide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mot de passe (seulement pour la création)
                    if (!isEditing)
                      TextFormField(
                        controller: controller.passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe *',
                          hintText: 'Entrez le mot de passe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),

                    if (!isEditing) const SizedBox(height: 16),

                    // Rôle
                    const Text(
                      'Rôle *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<int>(
                        value: controller.selectedRoleId.value,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items:
                            controller.getRolesList().map((role) {
                              return DropdownMenuItem<int>(
                                value: role['id'],
                                child: Text(role['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedRoleId.value = value;
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => ElevatedButton(
                              onPressed:
                                  controller.isCreating.value
                                      ? null
                                      : () async {
                                        if (isEditing) {
                                          // TODO: Implémenter la mise à jour
                                          Get.snackbar(
                                            'Info',
                                            'Fonctionnalité de modification en cours de développement',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        } else {
                                          final success =
                                              await controller.createUser();
                                          if (success) {
                                            Get.back();
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child:
                                  controller.isCreating.value
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(isEditing ? 'Modifier' : 'Créer'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations sur les rôles
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations sur les rôles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Administrateur: Gère les utilisateurs et paramètres\n'
                      '• Patron: Valide les documents et prend les décisions\n'
                      '• Commercial: Gère les clients et ventes\n'
                      '• Comptable: Gère la comptabilité et finances\n'
                      '• RH: Gère les employés et ressources humaines\n'
                      '• Technicien: Gère les interventions techniques',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
