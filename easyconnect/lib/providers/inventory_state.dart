import 'package:easyconnect/Models/inventory_session_model.dart';

class InventoryState {
  final List<InventorySession> sessions;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final String statusFilter;
  final InventorySession? currentSession;
  final bool isLoadingSession;

  const InventoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.statusFilter = 'all',
    this.currentSession,
    this.isLoadingSession = false,
  });

  bool get hasNextPage => currentPage < totalPages;

  InventoryState copyWith({
    List<InventorySession>? sessions,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    String? statusFilter,
    InventorySession? currentSession,
    bool? isLoadingSession,
  }) {
    return InventoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      statusFilter: statusFilter ?? this.statusFilter,
      currentSession: currentSession ?? this.currentSession,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession,
    );
  }
}
