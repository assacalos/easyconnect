import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/user_management_controller.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.loadUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed('/admin/users/new');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques rapides
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total utilisateurs',
                      value: controller.totalUsers.value.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Utilisateurs actifs',
                      value: controller.activeUsers.value.toString(),
                      icon: Icons.person,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Nouveaux ce mois',
                      value: controller.newUsersThisMonth.value.toString(),
                      icon: Icons.person_add,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Barre de recherche et filtres
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        controller.searchQuery.value = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un utilisateur...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: controller.selectedRole.value,
                    hint: const Text('Tous les rôles'),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Tous les rôles'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrateur'),
                      ),
                      DropdownMenuItem(value: 'patron', child: Text('Patron')),
                      DropdownMenuItem(
                        value: 'commercial',
                        child: Text('Commercial'),
                      ),
                      DropdownMenuItem(
                        value: 'comptable',
                        child: Text('Comptable'),
                      ),
                      DropdownMenuItem(value: 'rh', child: Text('RH')),
                      DropdownMenuItem(
                        value: 'technicien',
                        child: Text('Technicien'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedRole.value = value;
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des utilisateurs
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredUsers = controller.getFilteredUsers();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun utilisateur trouvé',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user: user, controller: controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard({
    required dynamic user,
    required UserManagementController controller,
  }) {
    final fullName = '${user.nom ?? ''} ${user.prenom ?? ''}'.trim();
    final roleName = controller.getRoleName(user.role);
    final roleColor = controller.getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.grey,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(fullName.isNotEmpty ? fullName : 'Utilisateur sans nom'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'Email non défini'),
            Text('Rôle: $roleName'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(roleName),
              backgroundColor: roleColor.withOpacity(0.1),
              labelStyle: TextStyle(color: roleColor),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Get.toNamed('/admin/users/${user.id}/edit');
                    break;
                  case 'toggle':
                    controller.toggleUserStatus(user.id, !user.isActive);
                    break;
                  case 'delete':
                    controller.deleteUser(user.id);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}
