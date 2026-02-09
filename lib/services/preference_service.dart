import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferenceService extends ChangeNotifier {
  static const String _communityFilterKey = "community_filter";
  static const String _lastVisitedTabKey = "last_tab";
  
  SharedPreferences? _prefs;

  PreferenceService() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  // Community Filter Persistence
  String get communityFilter => _prefs?.getString(_communityFilterKey) ?? 'All';

  Future<void> setCommunityFilter(String filter) async {
    await _prefs?.setString(_communityFilterKey, filter);
    notifyListeners();
  }

  // Last Visited Tab Persistence
  int get lastTab => _prefs?.getInt(_lastVisitedTabKey) ?? 0;

  Future<void> setLastTab(int index) async {
    await _prefs?.setInt(_lastVisitedTabKey, index);
    notifyListeners();
  }
}
