import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  final UserService service = UserService();

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      isLoading.value = true;
      users.value = await service.getUsers();
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void addUser(UserModel user, String password) async {
    try {
      isLoading.value = true;
      final newUser = await service.createUser(user, password);
      users.add(newUser);
      Get.back();
      Get.snackbar("Succès", "Utilisateur créé avec succès");
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateUser(UserModel user) async {
    try {
      isLoading.value = true;
      final updated = await service.updateUser(user);
      int index = users.indexWhere((u) => u.id == updated.id);
      if (index != -1) users[index] = updated;
      Get.back();
      Get.snackbar("Succès", "Utilisateur mis à jour");
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void deleteUser(String id) async {
    try {
      isLoading.value = true;
      await service.deleteUser(id);
      users.removeWhere((u) => u.id == id);
      Get.snackbar("Succès", "Utilisateur supprimé");
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
