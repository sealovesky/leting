import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/preference_service.dart';

class SearchProvider extends ChangeNotifier {
  final StorageService _storageService;
  final PreferenceService _preferenceService;

  List<Song> _results = [];
  List<String> _searchHistory = [];
  String _query = '';
  bool _isSearching = false;

  SearchProvider({
    required StorageService storageService,
    required PreferenceService preferenceService,
  })  : _storageService = storageService,
        _preferenceService = preferenceService {
    _searchHistory = _preferenceService.searchHistory;
  }

  List<Song> get results => _results;
  List<String> get searchHistory => _searchHistory;
  String get query => _query;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    _query = query;
    if (query.trim().isEmpty) {
      _results = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _results = await _storageService.searchSongs(query);
    _isSearching = false;
    notifyListeners();
  }

  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.sublist(0, 20);
    }
    _preferenceService.setSearchHistory(_searchHistory);
    notifyListeners();
  }

  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    _preferenceService.setSearchHistory(_searchHistory);
    notifyListeners();
  }

  void clearHistory() {
    _searchHistory.clear();
    _preferenceService.setSearchHistory([]);
    notifyListeners();
  }

  void clearResults() {
    _query = '';
    _results = [];
    _isSearching = false;
    notifyListeners();
  }
}
