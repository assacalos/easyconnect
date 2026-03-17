import 'package:easyconnect/Models/media_model.dart';

/// Remplacé par mediaProvider (Riverpod). Stub pour compatibilité.
class MediaController {
  static final MediaController _instance = MediaController._();
  static MediaController get to => _instance;
  factory MediaController() => _instance;
  MediaController._();

  final Map<String, List<MediaItem>> mediaByCategory = {};
  String selectedCategory = 'all';
  bool isLoading = false;
  final List<MediaItem> allMedia = [];
  List<MediaItem> getFilteredMedia() => [];
  int getMediaCount(String category) => 0;
  Future<void> loadMedia({bool forceRefresh = false}) async {}
  void filterByCategory(String category) {}
  Future<void> scanDocument() async {}
}
