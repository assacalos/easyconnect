import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientMyTicketsPage extends StatefulWidget {
  const ClientMyTicketsPage({super.key});

  @override
  State<ClientMyTicketsPage> createState() => _ClientMyTicketsPageState();
}

class _ClientMyTicketsPageState extends State<ClientMyTicketsPage> {
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
      final res = await ClientPortalService.getMyInterventions();
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

  static String _statusLabel(String? s) {
    switch (s) {
      case 'pending': return 'En attente';
      case 'approved': return 'Approuvée';
      case 'rejected': return 'Refusée';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminée';
      default: return s ?? '—';
    }
  }

  static Color _statusColor(String? s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'in_progress': return Colors.indigo;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
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
                    ? const Center(child: Text('Aucune demande pour le moment.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final t = _list[i] as Map<String, dynamic>;
                          final status = t['status']?.toString();
                          final scheduled = t['scheduled_date']?.toString();
                          final dateStr = scheduled != null && scheduled.length >= 10 ? scheduled.substring(0, 10) : '—';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(status).withOpacity(0.2),
                                child: Icon(Icons.build_circle, color: _statusColor(status)),
                              ),
                              title: Text(t['title']?.toString() ?? 'Demande'),
                              subtitle: Text('Date prévue: $dateStr'),
                              trailing: Chip(
                                label: Text(_statusLabel(status), style: const TextStyle(fontSize: 12)),
                                backgroundColor: _statusColor(status).withOpacity(0.2),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
