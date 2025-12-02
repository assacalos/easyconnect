import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  var users = <UserModel>[].obs;
  var isLoading = false.obs;

  final UserService service = UserService();

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  void fetchUsers({int page = 1}) async {
    try {
      isLoading.value = true;
      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await service.getUsersPaginated(
          page: page,
          perPage: perPage.value,
          search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          users.value = paginatedResponse.data;
        } else {
          // Pour les pages suivantes, ajouter les données
          users.addAll(paginatedResponse.data);
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        final usersList = await service.getUsers();
        if (page == 1) {
          users.value = usersList;
        } else {
          users.addAll(usersList);
        }
      }
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
      fetchUsers(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      fetchUsers(page: currentPage.value - 1);
    }
  }

  Future<bool> addUser(UserModel user, String password) async {
    try {
      isLoading.value = true;
      final newUser = await service.createUser(user, password);
      users.add(newUser);
      Get.snackbar("Succès", "Utilisateur créé avec succès");
      return true;
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      isLoading.value = true;
      final updated = await service.updateUser(user);
      int index = users.indexWhere((u) => u.id == updated.id);
      if (index != -1) users[index] = updated;
      Get.snackbar("Succès", "Utilisateur mis à jour");
      return true;
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void deleteUser(String id) async {
    try {
      isLoading.value = true;
      await service.deleteUser(int.parse(id));
      users.removeWhere((u) => u.id == id);
      Get.snackbar("Succès", "Utilisateur supprimé");
    } catch (e) {
      Get.snackbar("Erreur", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
