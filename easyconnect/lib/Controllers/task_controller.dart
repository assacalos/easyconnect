import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/services/task_service.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/error_helper.dart';

class TaskController {
  static final TaskController _instance = TaskController._();
  static TaskController get to => _instance;
  factory TaskController() => _instance;
  TaskController._();

  final TaskService _taskService = TaskService.to;
  final AuthController _authController = AuthController.to;
  final UserService _userService = UserService();

  bool isLoading = false;
  final List<TaskModel> tasks = [];
  TaskModel? currentTask;
  final List<UserModel> users = [];
  String? selectedStatus;
  int? selectedAssignedTo;

  int currentPage = 1;
  int lastPage = 1;
  int totalItems = 0;
  bool _isRefreshingFromApi = false;

  bool get canAssignTasks =>
      _authController.userAuth?.role == Roles.ADMIN ||
      _authController.userAuth?.role == Roles.PATRON;

  bool loadError = false;

  Future<void> loadTasks({
    int page = 1,
    bool append = false,
    bool isRetry = false,
    bool forceRefresh = false,
  }) async {
    if (page == 1) loadError = false;

    if (page == 1 && !append) {
      if (!forceRefresh) {
        final hiveList = TaskService.getCachedTaches();
        if (hiveList.isNotEmpty) {
          tasks.clear();
          tasks.addAll(hiveList);
          isLoading = false;
        }
      }
      Future.microtask(
        () => _refreshTasksFromApi(append: append, isRetry: isRetry),
      );
      return;
    }

    try {
      isLoading = true;
      final result = await _taskService.getTasks(
        page: page,
        perPage: 20,
        assignedTo: selectedAssignedTo,
        status: selectedStatus,
      );
      if (result['success'] == true) {
        final list = result['data'] as List<TaskModel>? ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        loadError = false;
        if (append) {
          tasks.addAll(list);
        } else {
          tasks.clear();
          tasks.addAll(list);
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
      if (page == 1) loadError = true;
      if (tasks.isEmpty) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger les tâches: $msg');
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refreshTasksFromApi({
    bool append = false,
    bool isRetry = false,
  }) async {
    if (_isRefreshingFromApi) return;
    _isRefreshingFromApi = true;
    try {
      isLoading = true;
      final result = await _taskService.getTasks(
        page: 1,
        perPage: 20,
        assignedTo: selectedAssignedTo,
        status: selectedStatus,
      );
      if (result['success'] == true) {
        final list = result['data'] as List<TaskModel>? ?? [];
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        loadError = false;
        tasks.clear();
        tasks.addAll(list);
        currentPage = pagination['current_page'] as int? ?? 1;
        lastPage = pagination['last_page'] as int? ?? 1;
        totalItems = pagination['total'] as int? ?? 0;
      }
    } catch (e) {
      if (!isRetry) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _refreshTasksFromApi(append: append, isRetry: true);
      }
      loadError = true;
      if (tasks.isEmpty) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger les tâches: $msg');
      }
    } finally {
      isLoading = false;
      _isRefreshingFromApi = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      final list = await _userService.getUsers();
      users.clear();
      users.addAll(list);
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger les utilisateurs');
    }
  }

  Future<TaskModel?> loadTask(int id) async {
    try {
      isLoading = true;
      currentTask = await _taskService.getTask(id);
      return currentTask;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger la tâche: $e');
      return null;
    } finally {
      isLoading = false;
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
      isLoading = true;
      await _taskService.createTask(
        titre: titre,
        description: description,
        assignedTo: assignedTo,
        priority: priority,
        dueDate: dueDate,
      );
      await loadTasks(page: 1);
      ErrorHelper.showSuccess('Tâche assignée avec succès');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateTaskStatus(int id, String status) async {
    try {
      isLoading = true;
      final updated = await _taskService.updateTaskStatus(id, status);
      final index = tasks.indexWhere((t) => t.id == id);
      if (index >= 0) tasks[index] = updated;
      if (currentTask?.id == id) currentTask = updated;
      ErrorHelper.showSuccess('Statut mis à jour');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
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
      isLoading = true;
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
      currentTask = updated;
      ErrorHelper.showSuccess('Tâche mise à jour');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      isLoading = true;
      await _taskService.deleteTask(id);
      tasks.removeWhere((t) => t.id == id);
      if (currentTask?.id == id) currentTask = null;
      ErrorHelper.showSuccess('Tâche supprimée');
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }

  void setStatusFilter(String? status) {
    selectedStatus = status;
    loadTasks(page: 1);
  }

  void setAssignedToFilter(int? userId) {
    selectedAssignedTo = userId;
    loadTasks(page: 1);
  }

  void clearFilters() {
    selectedStatus = null;
    selectedAssignedTo = null;
    loadTasks(page: 1);
  }
}
