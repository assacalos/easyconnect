import 'package:get_storage/get_storage.dart';

const String baseUrl =
    // "https://easykonect.smil-app.com/api"; // URL de production (pour APK sur téléphone)
    "http://10.0.2.2:8000/api"; // URL locale (pour émulateur Android)

final storage = GetStorage();
