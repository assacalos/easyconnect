import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientAnnouncementsPage extends StatefulWidget {
  const ClientAnnouncementsPage({super.key});

  @override
  State<ClientAnnouncementsPage> createState() => _ClientAnnouncementsPageState();
}

class _ClientAnnouncementsPageState extends State<ClientAnnouncementsPage> {
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
      final res = await ClientPortalService.getAnnouncements();
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
        title: const Text('Annonces & Promotions'),
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
                    ? const Center(child: Text('Aucune annonce pour le moment.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final a = _list[i] as Map<String, dynamic>;
                          final type = a['type']?.toString() ?? 'announcement';
                          final isPromo = type == 'promotion';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(isPromo ? Icons.local_offer : Icons.campaign, color: isPromo ? Colors.orange : Colors.teal),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          a['title']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (a['published_at'] != null)
                                        Text(
                                          a['published_at'].toString().length >= 10
                                              ? a['published_at'].toString().substring(0, 10)
                                              : '',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(a['content']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
