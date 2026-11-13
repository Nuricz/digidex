import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Favoritos y "registrados en el juego" (check), guardados en el dispositivo.
class CollectionStore extends ChangeNotifier {
  static const _favKey = 'favorites';
  static const _regKey = 'registered';

  final Set<String> _favorites = {};
  final Set<String> _registered = {};
  SharedPreferences? _prefs;

  bool isFavorite(String slug) => _favorites.contains(slug);
  bool isRegistered(String slug) => _registered.contains(slug);
  int get favoriteCount => _favorites.length;
  int get registeredCount => _registered.length;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _favorites.addAll(_prefs!.getStringList(_favKey) ?? const []);
      _registered.addAll(_prefs!.getStringList(_regKey) ?? const []);
      notifyListeners();
    } catch (_) {
      // Sin persistencia la app funciona igual (solo en memoria).
    }
  }

  Future<void> toggleFavorite(String slug) =>
      _toggle(_favorites, _favKey, slug);

  Future<void> toggleRegistered(String slug) =>
      _toggle(_registered, _regKey, slug);

  Future<void> _toggle(Set<String> set, String key, String slug) async {
    if (!set.add(slug)) set.remove(slug);
    notifyListeners();
    try {
      await (_prefs ??= await SharedPreferences.getInstance()).setStringList(
        key,
        set.toList(),
      );
    } catch (_) {}
  }
}
