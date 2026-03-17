import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientCatalogPage extends StatefulWidget {
  const ClientCatalogPage({super.key});

  @override
  State<ClientCatalogPage> createState() => _ClientCatalogPageState();
}

class _ClientCatalogPageState extends State<ClientCatalogPage> {
  List<dynamic> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ClientPortalService.getCatalog();
      if (!mounted) return;
      setState(() {
        _list = (res['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue & Articles'),
        backgroundColor: ClientDashboardPage.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : _list.isEmpty
                    ? const Center(child: Text('Aucun article pour le moment.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final a = _list[i] as Map<String, dynamic>;
                          final price = a['price'];
                          final priceStr = price != null ? (price is num ? price.toStringAsFixed(2) : price.toString()) : '—';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: a['image_url'] != null && (a['image_url'] as String).isNotEmpty
                                  ? Image.network(a['image_url'] as String, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2))
                                  : const Icon(Icons.inventory_2, size: 40),
                              title: Text(a['name']?.toString() ?? ''),
                              subtitle: a['description'] != null && (a['description'] as String).isNotEmpty
                                  ? Text((a['description'] as String).length > 80 ? '${(a['description'] as String).substring(0, 80)}...' : a['description'] as String)
                                  : null,
                              trailing: Text('$priceStr €', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
