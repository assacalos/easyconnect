import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/utils/error_helper.dart';

class UserController {
  static final UserController _instance = UserController._();
  static UserController get to => _instance;
  factory UserController() => _instance;
  UserController._();

  final List<UserModel> users = [];
  bool isLoading = false;
  final UserService service = UserService();

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';

  void fetchUsers({int page = 1}) async {
    try {
      isLoading = true;
      try {
        final paginatedResponse = await service.getUsersPaginated(
          page: page,
          perPage: perPage,
          search: searchQuery.isNotEmpty ? searchQuery : null,
        );
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;
        if (page == 1) {
          users.clear();
          users.addAll(paginatedResponse.data);
        } else {
          users.addAll(paginatedResponse.data);
        }
      } catch (e) {
        final usersList = await service.getUsers();
        if (page == 1) {
          users.clear();
          users.addAll(usersList);
        } else {
          users.addAll(usersList);
        }
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
    } finally {
      isLoading = false;
    }
  }

  void loadNextPage() {
    if (hasNextPage && !isLoading) fetchUsers(page: currentPage + 1);
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) fetchUsers(page: currentPage - 1);
  }

  Future<bool> addUser(UserModel user, String password) async {
    try {
      isLoading = true;
      final newUser = await service.createUser(user, password);
      users.add(newUser);
      ErrorHelper.showSuccess('Utilisateur créé avec succès');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      isLoading = true;
      final updated = await service.updateUser(user);
      final index = users.indexWhere((u) => u.id == updated.id);
      if (index != -1) users[index] = updated;
      ErrorHelper.showSuccess('Utilisateur mis à jour');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }

  void deleteUser(String id) async {
    try {
      isLoading = true;
      await service.deleteUser(int.parse(id));
      users.removeWhere((u) => u.id == id);
      ErrorHelper.showSuccess('Utilisateur supprimé');
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
    } finally {
      isLoading = false;
    }
  }
}
