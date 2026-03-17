import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/inventory_notifier.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:intl/intl.dart';

class InventoryListPage extends ConsumerStatefulWidget {
  const InventoryListPage({super.key});

  @override
  ConsumerState<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends ConsumerState<InventoryListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  static String _statusForIndex(int index) =>
      index == 0 ? 'all' : (index == 1 ? 'en_cours' : 'cloture');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(inventoryProvider.notifier).filterByStatus(
              _statusForIndex(_tabController.index),
            );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadSessions(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(
          fallbackRoute: '/comptable',
          iconColor: Colors.white,
        ),
        title: const Text('Inventaire physique'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadSessions(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En cours', icon: Icon(Icons.edit_note)),
            Tab(text: 'Clôturés', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: state.isLoading && state.sessions.isEmpty
          ? const SkeletonSearchResults(itemCount: 6)
          : state.sessions.isEmpty
              ? const Center(child: Text('Aucune session d\'inventaire'))
              : RefreshIndicator(
                  onRefresh: () => notifier.loadSessions(forceRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.sessions.length + (state.hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.sessions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final session = state.sessions[index];
                      return _SessionCard(
                        session: session,
                        dateFormat: dateFormat,
                        onTap: () => context.go(
                          '/comptable/inventaire/${session.id}',
                          extra: session,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, notifier),
        tooltip: 'Nouvelle session',
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, InventoryNotifier notifier) async {
    DateTime date = DateTime.now();
    String depot = '';

    final created = await showDialog<InventorySession>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nouvelle session d\'inventaire'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La session créera une ligne pour chaque article du stock (quantité théorique = stock actuel).',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Dépôt / Entrepôt (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => depot = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final session = await notifier.createSession(
                      date: date,
                      depot: depot.isEmpty ? null : depot,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop(session);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                child: const Text('Créer'),
              ),
            ],
          );
        },
      ),
    );

    if (created != null && context.mounted) {
      context.go('/comptable/inventaire/${created.id}', extra: created);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session créée')),
      );
    }
  }
}

class _SessionCard extends StatelessWidget {
  final InventorySession session;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = session.isClosed;
    final color = isClosed ? Colors.grey : Colors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isClosed ? Icons.check_circle : Icons.edit_note,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(DateTime.tryParse(session.date) ?? DateTime.now()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (session.depot != null && session.depot!.isNotEmpty)
                          Text(
                            session.depot!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(
                      session.statusText,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${session.items.length} article(s)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (session.isInProgress && session.variancesCount > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${session.variancesCount} écart(s)',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
