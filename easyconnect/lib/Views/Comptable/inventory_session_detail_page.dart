import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/inventory_notifier.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:intl/intl.dart';

class InventorySessionDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final InventorySession? session;

  const InventorySessionDetailPage({
    super.key,
    required this.sessionId,
    this.session,
  });

  @override
  ConsumerState<InventorySessionDetailPage> createState() =>
      _InventorySessionDetailPageState();
}

class _InventorySessionDetailPageState
    extends ConsumerState<InventorySessionDetailPage> {
  final Map<int, TextEditingController> _countedControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(inventoryProvider.notifier).loadSession(widget.sessionId);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _countedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(InventorySessionItem item) {
    if (!_countedControllers.containsKey(item.id)) {
      final c = TextEditingController(
        text: item.quantityCounted != null
            ? item.quantityCounted!.toStringAsFixed(0)
            : '',
      );
      _countedControllers[item.id] = c;
    }
    return _countedControllers[item.id]!;
  }

  Future<void> _saveCounted(InventorySessionItem item, String value) async {
    final qty = double.tryParse(value.replaceAll(',', '.'));
    if (qty == null || qty < 0) return;
    final notifier = ref.read(inventoryProvider.notifier);
    try {
      await notifier.updateItemCount(widget.sessionId, item.id, qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantité enregistrée'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _closeInventory() async {
    final notifier = ref.read(inventoryProvider.notifier);
    final session = ref.read(inventoryProvider).currentSession ?? widget.session;
    if (session == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer l\'inventaire'),
        content: const Text(
          'Les écarts seront appliqués aux quantités en stock (mouvements d\'ajustement). Cette action est irréversible. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await notifier.closeSession(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventaire clôturé')),
        );
        context.go('/comptable/inventaire');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final session = state.currentSession ?? widget.session;
    final isLoading = widget.session == null && state.isLoadingSession;
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (isLoading && session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBarBackButton(fallbackRoute: '/comptable/inventaire'),
          title: const Text('Inventaire'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBarBackButton(fallbackRoute: '/comptable/inventaire'),
          title: const Text('Inventaire'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Session non trouvée')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/comptable/inventaire'),
        title: Text('Inventaire ${dateFormat.format(DateTime.tryParse(session.date) ?? DateTime.now())}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (session.isInProgress)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(inventoryProvider.notifier).loadSession(widget.sessionId),
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: Column(
        children: [
          _HeaderCard(session: session, dateFormat: dateFormat),
          if (session.isInProgress && session.variancesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Text(
                        '${session.variancesCount} écart(s) à valider avant clôture',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Articles (quantité théorique = stock actuel)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...session.items.map((item) => _ItemRow(
                      item: item,
                      controller: _controllerFor(item),
                      enabled: session.isInProgress,
                      onSave: (v) => _saveCounted(item, v),
                    )),
              ],
            ),
          ),
          if (session.isInProgress)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _closeInventory,
                    icon: const Icon(Icons.lock),
                    label: const Text('Clôturer l\'inventaire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final InventorySession session;
  final DateFormat dateFormat;

  const _HeaderCard({required this.session, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final isClosed = session.isClosed;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isClosed ? Icons.check_circle : Icons.edit_note,
                  color: isClosed ? Colors.grey : Colors.teal,
                  size: 32,
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
                      Text(
                        session.depot ?? '—',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(session.statusText),
                  backgroundColor: isClosed
                      ? Colors.grey.shade200
                      : Colors.teal.shade50,
                  labelStyle: TextStyle(
                    color: isClosed ? Colors.grey.shade700 : Colors.teal.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${session.items.length} article(s)',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InventorySessionItem item;
  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onSave;

  const _ItemRow({
    required this.item,
    required this.controller,
    required this.enabled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final variance = item.quantityVariance;
    final hasVariance = variance != null && variance != 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.stock?.name ?? 'Article #${item.stockId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (item.stock != null)
                        Text(
                          '${item.stock!.sku} • ${item.stock!.category}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'Théorique: ${item.quantityTheoretical.toStringAsFixed(0)} ${item.stock?.unit ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Compté',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: onSave,
                    onTap: () => controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (hasVariance)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: variance > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: variance > 0
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      'Écart: ${variance > 0 ? '+' : ''}${variance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: variance > 0
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (item.quantityCounted != null)
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
