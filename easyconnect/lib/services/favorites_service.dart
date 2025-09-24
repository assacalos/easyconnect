import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FavoritesService extends GetxService {
  static FavoritesService get to => Get.find();

  final _storage = GetStorage();
  final favorites = <String>[].obs;
  static const _storageKey = 'favorites';

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  void _loadFavorites() {
    final storedFavorites = _storage.read<List?>(_storageKey);
    if (storedFavorites != null) {
      favorites.value = List<String>.from(storedFavorites);
    }
  }

  void _saveFavorites() {
    _storage.write(_storageKey, favorites.toList());
  }

  void toggleFavorite(String routeId) {
    if (isFavorite(routeId)) {
      favorites.remove(routeId);
    } else {
      favorites.add(routeId);
    }
    _saveFavorites();
  }

  bool isFavorite(String routeId) {
    return favorites.contains(routeId);
  }
}
