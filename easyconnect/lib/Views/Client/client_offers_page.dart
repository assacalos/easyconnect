import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientOffersPage extends StatefulWidget {
  const ClientOffersPage({super.key});

  @override
  State<ClientOffersPage> createState() => _ClientOffersPageState();
}

class _ClientOffersPageState extends State<ClientOffersPage> {
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
      final res = await ClientPortalService.getOffers();
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
        title: const Text('Offres'),
        backgroundColor: Colors.deepOrange,
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
                    ? const Center(child: Text('Aucune offre pour le moment.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final a = _list[i] as Map<String, dynamic>;
                          final price = a['price'];
                          final priceStr = price != null ? (price is num ? price.toStringAsFixed(2) : price.toString()) : '—';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.orange.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.local_offer, color: Colors.deepOrange, size: 40),
                              title: Text(a['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: a['description'] != null && (a['description'] as String).isNotEmpty ? Text(a['description'] as String) : null,
                              trailing: Text('$priceStr €', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
