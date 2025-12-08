import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/Views/Rh/pointage_detail.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PointageValidationPage extends StatefulWidget {
  const PointageValidationPage({super.key});

  @override
  State<PointageValidationPage> createState() => _PointageValidationPageState();
}

class _PointageValidationPageState extends State<PointageValidationPage> {
  final AttendanceController controller = Get.find<AttendanceController>();
  final AuthController _authController = Get.find<AuthController>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données après que le widget soit monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    try {
      await controller.loadAttendanceData();
      // Forcer la mise à jour de l'UI
      setState(() {});
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Pointages'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAttendanceData();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom d\'utilisateur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: Obx(() {
              // Forcer l'observation de attendanceHistory
              controller
                  .attendanceHistory
                  .length; // Accès pour déclencher la réactivité
              return controller.isLoading.value
                  ? const SkeletonSearchResults(itemCount: 6)
                  : _buildAttendanceList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Filtrer les pointages selon la recherche uniquement
    List<AttendancePunchModel> filteredPointages = controller.attendanceHistory;

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filteredPointages =
          filteredPointages
              .where(
                (pointage) => _getDisplayName(
                  pointage,
                ).toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    }

    if (filteredPointages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun pointage trouvé'
                  : 'Aucun pointage correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredPointages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final pointage = filteredPointages[index];
        return _buildPointageCard(context, pointage);
      },
    );
  }

  String _getDisplayName(AttendancePunchModel pointage) {
    final userName = pointage.userName ?? '';
    if (userName.toLowerCase().contains('comptable')) {
      final user = _authController.userAuth.value;
      if (user != null) {
        final displayName = '${user.prenom ?? ''} ${user.nom ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          return displayName;
        }
      }
    }
    return userName.isNotEmpty ? userName : 'Utilisateur inconnu';
  }

  Widget _buildPointageCard(
    BuildContext context,
    AttendancePunchModel pointage,
  ) {
    final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () => Get.to(() => PointageDetail(pointage: pointage)),
        borderRadius: BorderRadius.circular(8),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(
              pointage.type == 'check_in' ? Icons.login : Icons.logout,
              color: Colors.blue,
            ),
          ),
          title: Text(
            _getDisplayName(pointage),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Type: ${pointage.typeLabel}'),
              Text('Date: ${formatDateTime.format(pointage.timestamp)}'),
              Text('Lieu: ${pointage.address ?? 'Non spécifié'}'),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations employé
                  const Text(
                    'Informations employé',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Employé: ${_getDisplayName(pointage)}'),
                        Text('ID Employé: ${pointage.userId}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Détails du pointage
                  const Text(
                    'Détails du pointage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text('Type:'), Text(pointage.type)],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Heure:'),
                            Text(formatDateTime.format(pointage.timestamp)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lieu:'),
                            Text(pointage.address ?? 'Inconnu'),
                          ],
                        ),
                        // Photo affichée dans une section séparée ci-dessous
                        if (pointage.notes != null &&
                            pointage.notes!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Notes:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(pointage.notes!),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Photo du pointage
                  if (pointage.photoPath != null && pointage.photoPath!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Photo du pointage',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          pointage.photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image, color: Colors.red, size: 48),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Impossible de charger la photo',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
