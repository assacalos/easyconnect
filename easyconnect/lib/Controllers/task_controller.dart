import 'package:get/get.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/task_service.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class TaskController extends GetxController {
  final TaskService _taskService = Get.find<TaskService>();
  final AuthController _authController = Get.find<AuthController>();
  final UserService _userService = UserService();

  final isLoading = false.obs;
  final tasks = <TaskModel>[].obs;
  final currentTask = Rxn<TaskModel>();
  final users = <UserModel>[].obs;
  final selectedStatus = Rxn<String>();
  final selectedAssignedTo = Rxn<int>();

  int currentPage = 1;
  int lastPage = 1;
  int totalItems = 0;
  bool _isRefreshingFromApi = false;

  bool get canAssignTasks =>
      _authController.userAuth.value?.role == Roles.ADMIN ||
      _authController.userAuth.value?.role == Roles.PATRON;

  final loadError = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    loadError.value = false;
    isLoading.value = true;
    // Premier chargement déclenché par la page (TaskListPage) après le premier frame
    // pour éviter échec systématique au premier affichage.
  }

  Future<void> loadTasks({
    int page = 1,
    bool append = false,
    bool isRetry = false,
  }) async {
    if (page == 1) loadError.value = false;

    // 1) Remplir immédiatement depuis Hive (page 1 uniquement)
    if (page == 1 && !append) {
      final hiveList = TaskService.getCachedTaches();
      if (hiveList.isNotEmpty) {
        tasks.value = hiveList;
        isLoading.value = false;
      }
      // Lancer l'API en arrière-plan pour la page 1
      Future.microtask(
        () => _refreshTasksFromApi(append: append, isRetry: isRetry),
      );
      return;
    }

    try {
      isLoading.value = true;
      final result = await _taskService.getTasks(
        page: page,
        perPage: 20,
        assignedTo: selectedAssignedTo.value,
        status: selectedStatus.value,
      );
      if (result['success'] == true) {
        final list = result['data'] as List<TaskModel>? ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        loadError.value = false;
        if (append) {
          tasks.addAll(list);
        } else {
          tasks.value = list;
        }
        currentPage = pagination['current_page'] as int? ?? page;
        lastPage = pagination['last_page'] as int? ?? 1;
        totalItems = pagination['total'] as int? ?? 0;
      }
    } catch (e) {
      if (page == 1 && !isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return loadTasks(page: page, append: append, isRetry: true);
      }
      if (page == 1) loadError.value = true;
      // Ne pas effacer les données déjà affichées (Hive)
      if (tasks.isEmpty) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        Get.snackbar('Erreur', 'Impossible de charger les tâches: $msg');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshTasksFromApi({
    bool append = false,
    bool isRetry = false,
  }) async {
    if (_isRefreshingFromApi) return;
    _isRefreshingFromApi = true;
    try {
      isLoading.value = true;
      final result = await _taskService.getTasks(
        page: 1,
        perPage: 20,
        assignedTo: selectedAssignedTo.value,
        status: selectedStatus.value,
      );
      if (result['success'] == true) {
        final list = result['data'] as List<TaskModel>? ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        loadError.value = false;
        tasks.value = list;
        currentPage = pagination['current_page'] as int? ?? 1;
        lastPage = pagination['last_page'] as int? ?? 1;
        totalItems = pagination['total'] as int? ?? 0;
      }
    } catch (e) {
      if (!isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _refreshTasksFromApi(append: append, isRetry: true);
      }
      loadError.value = true;
      if (tasks.isEmpty) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        Get.snackbar('Erreur', 'Impossible de charger les tâches: $msg');
      }
    } finally {
      isLoading.value = false;
      _isRefreshingFromApi = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      final list = await _userService.getUsers();
      users.value = list;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les utilisateurs');
    }
  }

  Future<TaskModel?> loadTask(int id) async {
    try {
      isLoading.value = true;
      currentTask.value = await _taskService.getTask(id);
      return currentTask.value;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger la tâche: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTask({
    required String titre,
    String? description,
    required int assignedTo,
    String priority = 'medium',
    String? dueDate,
  }) async {
    try {
      isLoading.value = true;
      await _taskService.createTask(
        titre: titre,
        description: description,
        assignedTo: assignedTo,
        priority: priority,
        dueDate: dueDate,
      );
      await loadTasks(page: 1);
      Get.snackbar('Succès', 'Tâche assignée avec succès');
      return true;
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTaskStatus(int id, String status) async {
    try {
      isLoading.value = true;
      final updated = await _taskService.updateTaskStatus(id, status);
      final index = tasks.indexWhere((t) => t.id == id);
      if (index >= 0) tasks[index] = updated;
      if (currentTask.value?.id == id) currentTask.value = updated;
      Get.snackbar('Succès', 'Statut mis à jour');
      return true;
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTask(
    int id, {
    String? titre,
    String? description,
    int? assignedTo,
    String? status,
    String? priority,
    String? dueDate,
  }) async {
    try {
      isLoading.value = true;
      final updated = await _taskService.updateTask(
        id,
        titre: titre,
        description: description,
        assignedTo: assignedTo,
        status: status,
        priority: priority,
        dueDate: dueDate,
      );
      final index = tasks.indexWhere((t) => t.id == id);
      if (index >= 0) tasks[index] = updated;
      currentTask.value = updated;
      Get.snackbar('Succès', 'Tâche mise à jour');
      return true;
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      isLoading.value = true;
      await _taskService.deleteTask(id);
      tasks.removeWhere((t) => t.id == id);
      if (currentTask.value?.id == id) currentTask.value = null;
      Get.snackbar('Succès', 'Tâche supprimée');
      return true;
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void setStatusFilter(String? status) {
    selectedStatus.value = status;
    loadTasks(page: 1);
  }

  void setAssignedToFilter(int? userId) {
    selectedAssignedTo.value = userId;
    loadTasks(page: 1);
  }

  void clearFilters() {
    selectedStatus.value = null;
    selectedAssignedTo.value = null;
    loadTasks(page: 1);
  }
}
