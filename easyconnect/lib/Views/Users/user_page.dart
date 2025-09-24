import 'package:easyconnect/Controllers/userController.dart';
import 'package:easyconnect/Views/Users/user_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserPage extends StatelessWidget {
  final UserController controller = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des Utilisateurs"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Get.to(() => UserForm()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        if (controller.users.isEmpty) {
          return Center(child: Text("Aucun utilisateur trouvé"));
        }
        return ListView.builder(
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return ListTile(
              title: Text("${user.nom} ${user.prenom}"),
              subtitle: Text("${user.email} • ${user.role}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Get.to(() => UserForm(user: user)),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDelete(user.id.toString()),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _confirmDelete(String id) {
    Get.defaultDialog(
      title: "Supprimer",
      middleText: "Voulez-vous vraiment supprimer cet utilisateur ?",
      textConfirm: "Oui",
      textCancel: "Non",
      onConfirm: () {
        controller.deleteUser(id);
        Get.back();
      },
    );
  }
}
