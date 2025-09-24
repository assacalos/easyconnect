import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogsSection extends StatelessWidget {
  final RxList<Map<String, String>> logs =
      <Map<String, String>>[
        {"user": "John Doe", "action": "Connexion", "date": "2025-09-18 10:00"},
        {
          "user": "Alice Smith",
          "action": "Création utilisateur",
          "date": "2025-09-18 10:30",
        },
        {
          "user": "Bob Johnson",
          "action": "Modification mot de passe",
          "date": "2025-09-18 11:00",
        },
      ].obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (query) {
                // filtrage simple
                logs.value =
                    logs.where((log) {
                      return log["user"]!.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ||
                          log["action"]!.toLowerCase().contains(
                            query.toLowerCase(),
                          );
                    }).toList();
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(log["action"]!),
                    subtitle: Text("${log["user"]} • ${log["date"]}"),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
