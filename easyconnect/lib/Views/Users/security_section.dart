import 'package:easyconnect/Controllers/userController.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SecuritySection extends StatelessWidget {
  final UserController controller = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: Colors.blueGrey));
      }
      if (controller.users.isEmpty) {
        return Center(child: Text("Aucun utilisateur trouvé"));
      }

      return ListView.builder(
        itemCount: controller.users.length,
        itemBuilder: (context, index) {
          final user = controller.users[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text("${user.nom} ${user.prenom}"),
              subtitle: Text("${user.email} • Rôle: ${user.role}"),
              trailing: Switch(
                value: user.isActive,
                onChanged: (value) {
                  final updatedUser = UserModel(
                    id: user.id,
                    nom: user.nom,
                    prenom: user.prenom,
                    email: user.email,
                    role: user.role,
                    isActive: value,
                  );
                  controller.updateUser(updatedUser);
                },
              ),
            ),
          );
        },
      );
    });
  }
}
