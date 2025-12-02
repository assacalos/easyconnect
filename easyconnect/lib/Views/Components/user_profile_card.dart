import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/permission_list.dart';

class UserProfileCard extends StatelessWidget {
  final bool showPermissions;
  final bool expanded;

  const UserProfileCard({
    super.key,
    this.showPermissions = true,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Obx ciblé uniquement sur userAuth - ne reconstruit que si l'utilisateur change
    return Obx(() {
      final user = authController.userAuth.value;
      if (user == null) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                child: Text(
                  (user.prenom?.isNotEmpty == true
                          ? user.prenom![0]
                          : user.nom?.isNotEmpty == true
                          ? user.nom![0]
                          : "?")
                      .toUpperCase(),
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                "${user.prenom ?? ''} ${user.nom ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(user.email ?? ''),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Roles.getRoleName(user.role),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authController.logout(),
              ),
            ),
            if (showPermissions) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Permissions",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PermissionList(
                      userRole: user.role,
                      showOnlyGranted: !expanded,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
