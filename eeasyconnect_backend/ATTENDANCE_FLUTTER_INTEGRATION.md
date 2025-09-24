# 📱 Intégration Flutter - Système de Pointage

## 🎯 **Vue d'ensemble**

Le système de pointage permet aux utilisateurs de pointer leur arrivée et départ avec géolocalisation, photos et gestion des retards.

## 🔗 **Endpoints API**

### **Base URL**: `http://127.0.0.1:8000/api`

### **Authentification**
Tous les endpoints nécessitent un token Bearer dans l'en-tête :
```
Authorization: Bearer {token}
```

## 📋 **Endpoints Disponibles**

### **1. Liste des Pointages**
```http
GET /attendances
```

**Paramètres de requête :**
- `user_id` (optionnel) : ID de l'utilisateur
- `date_debut` (optionnel) : Date de début (YYYY-MM-DD)
- `date_fin` (optionnel) : Date de fin (YYYY-MM-DD)
- `status` (optionnel) : `present`, `late`, `early_leave`
- `per_page` (optionnel) : Nombre d'éléments par page (défaut: 15)

**Réponse :**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "user_id": 2,
        "user_name": "Jean Dupont",
        "user_role": "Commercial",
        "check_in_time": "2025-09-24 08:15:00",
        "check_out_time": "2025-09-24 17:30:00",
        "status": "late",
        "location": {
          "latitude": 5.359952,
          "longitude": -4.008256,
          "address": "Abidjan, Côte d'Ivoire",
          "accuracy": 10,
          "timestamp": "2025-09-24T08:15:00.000Z"
        },
        "photo_path": "photos/attendance_2_2025_09_24.jpg",
        "notes": "Retard dû aux embouteillages",
        "work_duration_hours": 8.25,
        "is_late": true,
        "late_minutes": 15,
        "created_at": "2025-09-24 08:15:00",
        "updated_at": "2025-09-24 17:30:00"
      }
    ],
    "total": 150
  },
  "message": "Liste des pointages récupérée avec succès"
}
```

### **2. Détails d'un Pointage**
```http
GET /attendances/{id}
```

**Réponse :** Même format que l'élément dans la liste

### **3. Pointer l'Arrivée**
```http
POST /attendances/check-in
```

**Body :**
```json
{
  "location": {
    "latitude": 5.359952,
    "longitude": -4.008256,
    "address": "Abidjan, Côte d'Ivoire",
    "accuracy": 10,
    "timestamp": "2025-09-24T08:15:00.000Z"
  },
  "photo_path": "photos/attendance_2_2025_09_24.jpg",
  "notes": "Arrivée à l'heure"
}
```

### **4. Pointer le Départ**
```http
POST /attendances/check-out
```

**Body :**
```json
{
  "notes": "Journée productive"
}
```

### **5. Mettre à jour un Pointage**
```http
PUT /attendances/{id}
```

**Body :**
```json
{
  "check_in_time": "2025-09-24 08:00:00",
  "check_out_time": "2025-09-24 17:00:00",
  "status": "present",
  "notes": "Pointage corrigé"
}
```

### **6. Supprimer un Pointage**
```http
DELETE /attendances/{id}
```

### **7. Statut Actuel**
```http
GET /attendances/current-status
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "can_check_in": true,
    "can_check_out": false,
    "today_attendance": {
      "id": 1,
      "check_in_time": "2025-09-24 08:15:00",
      "check_out_time": null,
      "status": "late",
      "work_duration_hours": null
    }
  },
  "message": "Statut de pointage récupéré avec succès"
}
```

### **8. Statistiques de Pointage**
```http
GET /attendances-statistics
```

**Paramètres :**
- `user_id` (optionnel) : ID de l'utilisateur
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin

**Réponse :**
```json
{
  "success": true,
  "data": {
    "total_days": 20,
    "present_days": 18,
    "absent_days": 2,
    "late_days": 5,
    "average_hours": 8.2,
    "attendance_rate": 90.0,
    "recent_attendance": [...],
    "monthly_stats": {
      "1": 20,
      "2": 18,
      "3": 22,
      "4": 19,
      "5": 21,
      "6": 20,
      "7": 18,
      "8": 22,
      "9": 19,
      "10": 21,
      "11": 20,
      "12": 18
    }
  },
  "message": "Statistiques récupérées avec succès"
}
```

### **9. Paramètres de Pointage**
```http
GET /attendance-settings
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "allowed_radius": 100,
    "work_start_time": "08:00",
    "work_end_time": "17:00",
    "late_threshold_minutes": 15,
    "require_photo": true,
    "require_location": true,
    "allowed_locations": [
      {
        "name": "Bureau Principal",
        "latitude": 5.359952,
        "longitude": -4.008256,
        "address": "Abidjan, Côte d'Ivoire"
      }
    ]
  },
  "message": "Paramètres récupérés avec succès"
}
```

## 🏗️ **Modèles Dart**

### **AttendanceModel**
```dart
class AttendanceModel {
  final int id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'present', 'late', 'early_leave'
  final LocationInfo location;
  final String? photoPath;
  final String? notes;
  final double? workDurationHours;
  final bool isLate;
  final int lateMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.location,
    this.photoPath,
    this.notes,
    this.workDurationHours,
    required this.isLate,
    required this.lateMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userRole: json['user_role'],
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      status: json['status'],
      location: LocationInfo.fromJson(json['location']),
      photoPath: json['photo_path'],
      notes: json['notes'],
      workDurationHours: json['work_duration_hours']?.toDouble(),
      isLate: json['is_late'] ?? false,
      lateMinutes: json['late_minutes'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'status': status,
      'location': location.toJson(),
      'photo_path': photoPath,
      'notes': notes,
      'work_duration_hours': workDurationHours,
      'is_late': isLate,
      'late_minutes': lateMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### **LocationInfo**
```dart
class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

### **AttendanceStats**
```dart
class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double averageHours;
  final double attendanceRate;
  final List<AttendanceModel> recentAttendance;
  final Map<String, int> monthlyStats;

  AttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.averageHours,
    required this.attendanceRate,
    required this.recentAttendance,
    required this.monthlyStats,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      averageHours: (json['average_hours'] ?? 0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0).toDouble(),
      recentAttendance: (json['recent_attendance'] as List<dynamic>?)
          ?.map((e) => AttendanceModel.fromJson(e))
          .toList() ?? [],
      monthlyStats: Map<String, int>.from(json['monthly_stats'] ?? {}),
    );
  }
}
```

### **AttendanceSettings**
```dart
class AttendanceSettings {
  final double allowedRadius;
  final String workStartTime;
  final String workEndTime;
  final int lateThresholdMinutes;
  final bool requirePhoto;
  final bool requireLocation;
  final List<AllowedLocation> allowedLocations;

  AttendanceSettings({
    required this.allowedRadius,
    required this.workStartTime,
    required this.workEndTime,
    required this.lateThresholdMinutes,
    required this.requirePhoto,
    required this.requireLocation,
    required this.allowedLocations,
  });

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      allowedRadius: (json['allowed_radius'] ?? 100).toDouble(),
      workStartTime: json['work_start_time'] ?? '08:00',
      workEndTime: json['work_end_time'] ?? '17:00',
      lateThresholdMinutes: json['late_threshold_minutes'] ?? 15,
      requirePhoto: json['require_photo'] ?? true,
      requireLocation: json['require_location'] ?? true,
      allowedLocations: (json['allowed_locations'] as List<dynamic>?)
          ?.map((e) => AllowedLocation.fromJson(e))
          .toList() ?? [],
    );
  }
}

class AllowedLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  AllowedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory AllowedLocation.fromJson(Map<String, dynamic> json) {
    return AllowedLocation(
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
    );
  }
}
```

## 🎨 **Widgets Flutter Recommandés**

### **1. Widget de Pointage Principal**
```dart
class AttendanceWidget extends StatefulWidget {
  @override
  _AttendanceWidgetState createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  bool _canCheckIn = false;
  bool _canCheckOut = false;
  AttendanceModel? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  void _loadCurrentStatus() async {
    try {
      final status = await AttendanceService.getCurrentStatus();
      setState(() {
        _canCheckIn = status['can_check_in'];
        _canCheckOut = status['can_check_out'];
        _todayAttendance = status['today_attendance'] != null 
            ? AttendanceModel.fromJson(status['today_attendance'])
            : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Pointage',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            if (_canCheckIn)
              ElevatedButton.icon(
                onPressed: _checkIn,
                icon: Icon(Icons.login),
                label: Text('Pointer l\'arrivée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            if (_canCheckOut)
              ElevatedButton.icon(
                onPressed: _checkOut,
                icon: Icon(Icons.logout),
                label: Text('Pointer le départ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            if (_todayAttendance != null)
              _buildTodayAttendance(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendance() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pointage d\'aujourd\'hui:'),
          Text('Arrivée: ${_formatTime(_todayAttendance!.checkInTime)}'),
          if (_todayAttendance!.checkOutTime != null)
            Text('Départ: ${_formatTime(_todayAttendance!.checkOutTime!)}'),
          Text('Statut: ${_getStatusText(_todayAttendance!.status)}'),
        ],
      ),
    );
  }

  void _checkIn() async {
    try {
      // Obtenir la géolocalisation
      final location = await _getCurrentLocation();
      
      // Prendre une photo si requis
      String? photoPath;
      if (await _isPhotoRequired()) {
        photoPath = await _takePhoto();
      }

      await AttendanceService.checkIn(
        location: location,
        photoPath: photoPath,
        notes: 'Pointage d\'arrivée',
      );

      _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arrivée pointée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _checkOut() async {
    try {
      await AttendanceService.checkOut(notes: 'Pointage de départ');
      
      _loadCurrentStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Départ pointé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}
```

### **2. Liste des Pointages**
```dart
class AttendanceListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceModel>>(
      future: AttendanceService.getAttendances(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        final attendances = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: attendances.length,
          itemBuilder: (context, index) {
            final attendance = attendances[index];
            return AttendanceCard(attendance: attendance);
          },
        );
      },
    );
  }
}
```

### **3. Carte de Pointage**
```dart
class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  
  const AttendanceCard({required this.attendance});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getStatusIcon(attendance.status),
        title: Text(_formatDate(attendance.checkInTime)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arrivée: ${_formatTime(attendance.checkInTime)}'),
            if (attendance.checkOutTime != null)
              Text('Départ: ${_formatTime(attendance.checkOutTime!)}'),
            if (attendance.workDurationHours != null)
              Text('Durée: ${attendance.workDurationHours!.toStringAsFixed(1)}h'),
          ],
        ),
        trailing: attendance.isLate 
            ? Chip(
                label: Text('${attendance.lateMinutes}min de retard'),
                backgroundColor: Colors.orange,
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceDetail(attendance: attendance),
          ),
        ),
      ),
    );
  }
  
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'late':
        return Icon(Icons.schedule, color: Colors.orange);
      case 'early_leave':
        return Icon(Icons.exit_to_app, color: Colors.red);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }
}
```

### **4. Statistiques de Pointage**
```dart
class AttendanceStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AttendanceStats>(
      future: AttendanceService.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        final stats = snapshot.data!;
        
        return Column(
          children: [
            _buildStatsRow('Jours présents', stats.presentDays, Colors.green),
            _buildStatsRow('Jours d\'absence', stats.absentDays, Colors.red),
            _buildStatsRow('Retards', stats.lateDays, Colors.orange),
            _buildStatsRow('Heures moyennes', stats.averageHours, Colors.blue),
            _buildStatsRow('Taux de présence', stats.attendanceRate, Colors.purple),
          ],
        );
      },
    );
  }
  
  Widget _buildStatsRow(String label, dynamic value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔐 **Gestion des Permissions**

### **Rôles et Accès**
- **Tous les utilisateurs** : Peuvent pointer leur arrivée/départ
- **RH/Admin/Patron** : Peuvent voir tous les pointages
- **Commercial/Comptable/Technicien** : Voient seulement leurs pointages

### **Fonctionnalités de Sécurité**
1. **Géolocalisation** : Vérification de la zone autorisée
2. **Photos** : Capture obligatoire selon les paramètres
3. **Horaires** : Détection automatique des retards
4. **Validation** : Vérification des données avant enregistrement

## 📱 **Fonctionnalités Recommandées**

### **1. Pointage Rapide**
- Bouton principal pour pointer
- Géolocalisation automatique
- Capture photo rapide
- Validation en temps réel

### **2. Historique**
- Liste des pointages avec filtres
- Recherche par date/statut
- Export des données
- Graphiques de performance

### **3. Notifications**
- Rappel de pointage
- Alertes de retard
- Notifications de validation
- Rapports automatiques

### **4. Géolocalisation**
- Carte des zones autorisées
- Navigation vers le bureau
- Historique des positions
- Validation de distance

## 🚀 **Exemple d'Utilisation**

```dart
// Pointer l'arrivée
final location = await Geolocator.getCurrentPosition();
await AttendanceService.checkIn(
  location: {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'address': 'Adresse actuelle',
    'accuracy': location.accuracy,
    'timestamp': DateTime.now().toIso8601String(),
  },
  photoPath: 'photos/attendance_123.jpg',
  notes: 'Arrivée à l\'heure',
);

// Pointer le départ
await AttendanceService.checkOut(
  notes: 'Journée productive',
);

// Obtenir les statistiques
final stats = await AttendanceService.getStatistics(
  dateDebut: DateTime(2025, 9, 1),
  dateFin: DateTime(2025, 9, 30),
);
```

## ⚠️ **Points d'Attention**

1. **Géolocalisation** : Demander les permissions appropriées
2. **Photos** : Gérer le stockage et la compression
3. **Performance** : Optimiser les requêtes de géolocalisation
4. **Sécurité** : Valider les données côté client ET serveur
5. **UX** : Interface intuitive et responsive

## 📊 **Métriques Disponibles**

### **Statistiques Individuelles**
- Jours présents/absents
- Nombre de retards
- Heures moyennes de travail
- Taux de présence
- Historique mensuel

### **Statistiques Globales** (RH/Admin)
- Pointages par utilisateur
- Tendances de présence
- Zones de pointage populaires
- Analyses de performance

Ce système de pointage est maintenant **100% fonctionnel** et prêt pour l'intégration Flutter ! 🎯✨
