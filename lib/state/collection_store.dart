import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Respaldo exportable de favoritos y registrados (texto JSON, sin plugins).
class CollectionBackup {
  static const _app = 'digidex';
  static const _version = 1;

  final Set<String> favorites, registered;
  const CollectionBackup(this.favorites, this.registered);

  String toJson() => jsonEncode({
    'app': _app,
    'version': _version,
    'favorites': favorites.toList()..sort(),
    'registered': registered.toList()..sort(),
  });

  /// Lanza [FormatException] con un mensaje claro si el texto no es válido.
  factory CollectionBackup.parse(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text.trim());
    } on FormatException {
      throw const FormatException('El texto no es un respaldo válido.');
    }
    final j = decoded;
    if (j is! Map<String, dynamic> || j['app'] != _app) {
      throw const FormatException('No parece un respaldo de DigiDex.');
    }
    if (j['version'] != _version) {
      throw const FormatException('Versión de respaldo no soportada.');
    }
    Set<String> names(String key) {
      final v = j[key];
      if (v is! List) throw FormatException('Al respaldo le falta "$key".');
      return {
        for (final e in v)
          if (e is String) e,
      };
    }

    return CollectionBackup(names('favorites'), names('registered'));
  }
}

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

  CollectionBackup snapshot() =>
      CollectionBackup({..._favorites}, {..._registered});

  /// Aplica un respaldo. Los Digimon que no estén en [validSlugs] se ignoran.
  /// Con [replace] pisa lo actual; si no, lo combina (unión).
  Future<({int favorites, int registered, int ignored})> restore(
    CollectionBackup backup, {
    required bool replace,
    required Set<String> validSlugs,
  }) async {
    final favs = backup.favorites.where(validSlugs.contains).toSet();
    final regs = backup.registered.where(validSlugs.contains).toSet();
    final ignored =
        (backup.favorites.length - favs.length) +
        (backup.registered.length - regs.length);
    if (replace) {
      _favorites
        ..clear()
        ..addAll(favs);
      _registered
        ..clear()
        ..addAll(regs);
    } else {
      _favorites.addAll(favs);
      _registered.addAll(regs);
    }
    notifyListeners();
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setStringList(_favKey, _favorites.toList());
      await prefs.setStringList(_regKey, _registered.toList());
    } catch (_) {}
    return (favorites: favs.length, registered: regs.length, ignored: ignored);
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
