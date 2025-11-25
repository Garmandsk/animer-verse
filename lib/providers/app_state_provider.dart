import 'package:anime_verse/models/anime.dart';
import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _storageKey = 'favorite_animes';
  List<Anime> _favoriteAnimes = [];
  List<Anime> get favoriteAnimes => _favoriteAnimes;

  AppStateProvider() {
    _loadFavorites();
  }

  Future <void> _loadFavorites() async {
    // Load favorite animes from persistent storage
    // This is a placeholder for actual storage loading logic
    // For example, using SharedPreferences or Hive
    // After loading, call notifyListeners();
  }
  
  Future <void> _saveFavorites() async {
    // Save favorite animes to persistent storage
    // This is a placeholder for actual storage saving logic
    // For example, using SharedPreferences or Hive
  }
  
  bool isFavorite(String animeId) {
    return _favoriteAnimes.any((anime) => anime.id == animeId);
  }

  void addFavorite(Anime anime) {
    if (!isFavorite(anime.id)) {
      _favoriteAnimes.add(anime);
      _saveFavorites();
      notifyListeners();
    }
    _favoriteAnimes.add(anime);
    notifyListeners();
  }

  void removeFavorite(String animeId) {
    _favoriteAnimes.removeWhere((anime) => anime.id == animeId);
    _saveFavorites();
    notifyListeners();
  }
  
  void toggleFavorite(Anime anime) {

    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
    notifyListeners();
  }

}