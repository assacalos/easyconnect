import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/providers/inventory_state.dart';
import 'package:easyconnect/services/inventory_service.dart';

final inventoryProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);

class InventoryNotifier extends Notifier<InventoryState> {
  final _service = InventoryService();

  @override
  InventoryState build() => const InventoryState();

  Future<void> loadSessions({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      currentPage: 1,
      sessions: forceRefresh ? [] : state.sessions,
    );
    try {
      final res = await _service.getSessions(
        status: state.statusFilter == 'all' ? null : state.statusFilter,
        page: 1,
        perPage: 20,
      );
      state = state.copyWith(
        sessions: res.data,
        isLoading: false,
        currentPage: res.currentPage,
        totalPages: res.lastPage,
        totalItems: res.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasNextPage) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final res = await _service.getSessions(
        status: state.statusFilter == 'all' ? null : state.statusFilter,
        page: nextPage,
        perPage: 20,
      );
      state = state.copyWith(
        sessions: [...state.sessions, ...res.data],
        isLoadingMore: false,
        currentPage: res.currentPage,
        totalPages: res.lastPage,
        totalItems: res.total,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      rethrow;
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(statusFilter: status);
    loadSessions(forceRefresh: true);
  }

  Future<InventorySession> createSession({
    required DateTime date,
    String? depot,
  }) async {
    final session = await _service.createSession(date: date, depot: depot);
    state = state.copyWith(sessions: [session, ...state.sessions]);
    return session;
  }

  Future<InventorySession> loadSession(int id) async {
    state = state.copyWith(isLoadingSession: true, currentSession: null);
    try {
      final session = await _service.getSession(id);
      state = state.copyWith(currentSession: session, isLoadingSession: false);
      return session;
    } catch (e) {
      state = state.copyWith(isLoadingSession: false);
      rethrow;
    }
  }

  Future<InventorySession> updateItemCount(
    int sessionId,
    int itemId,
    double quantityCounted,
  ) async {
    await _service.updateItemCount(sessionId, itemId, quantityCounted);
    if (state.currentSession?.id == sessionId) {
      return loadSession(sessionId);
    }
    return _service.getSession(sessionId);
  }

  Future<InventorySession> updateSessionItems(
    int sessionId,
    List<Map<String, dynamic>> items,
  ) async {
    final session = await _service.updateSession(sessionId, items: items);
    if (state.currentSession?.id == sessionId) {
      state = state.copyWith(currentSession: session);
    }
    return session;
  }

  Future<InventorySession> closeSession(int id) async {
    final session = await _service.closeSession(id);
    state = state.copyWith(
      currentSession: state.currentSession?.id == id ? session : state.currentSession,
      sessions: state.sessions.map((s) => s.id == id ? session : s).toList(),
    );
    return session;
  }

  Future<void> deleteSession(int id) async {
    await _service.deleteSession(id);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != id).toList(),
      currentSession: state.currentSession?.id == id ? null : state.currentSession,
    );
  }

  void clearCurrentSession() {
    state = state.copyWith(currentSession: null);
  }
}
