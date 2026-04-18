import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/generated_menu_models.dart';
import '../utils/app_logger.dart';

/// Service để lưu trữ dữ liệu cục bộ sử dụng SharedPreferences
class LocalStorageService {
  static const String _savedMenuPlansKey = 'saved_ai_menu_plans';
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  // Private constructor
  LocalStorageService._();

  /// Get singleton instance
  factory LocalStorageService() {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  /// Initialize SharedPreferences - Phải gọi trước khi sử dụng
  static Future<LocalStorageService> getInstance() async {
    if (_prefs == null) {
      _instance ??= LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('LocalStorageService initialized');
    }
    return _instance!;
  }

  /// Đảm bảo _prefs đã được khởi tạo
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'LocalStorageService chưa được khởi tạo. Vui lòng gọi LocalStorageService.getInstance() trước.',
      );
    }
    return _prefs!;
  }

  // ==================== Token Management ====================

  /// Save authentication token
  Future<bool> saveToken(String token) async {
    try {
      return await prefs.setString(AppConfig.tokenKey, token);
    } catch (e) {
      AppLogger.error('Error saving token', e);
      return false;
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      return prefs.getString(AppConfig.tokenKey);
    } catch (e) {
      AppLogger.error('Error getting token', e);
      return null;
    }
  }

  /// Remove authentication token
  Future<bool> removeToken() async {
    try {
      return await prefs.remove(AppConfig.tokenKey);
    } catch (e) {
      AppLogger.error('Error removing token', e);
      return false;
    }
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      return await prefs.setString(AppConfig.refreshTokenKey, refreshToken);
    } catch (e) {
      AppLogger.error('Error saving refresh token', e);
      return false;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return prefs.getString(AppConfig.refreshTokenKey);
    } catch (e) {
      AppLogger.error('Error getting refresh token', e);
      return null;
    }
  }

  /// Remove refresh token
  Future<bool> removeRefreshToken() async {
    try {
      return await prefs.remove(AppConfig.refreshTokenKey);
    } catch (e) {
      AppLogger.error('Error removing refresh token', e);
      return false;
    }
  }

  // ==================== Shop Status Management ====================

  /// Save shop status by ID (survives logout)
  Future<bool> saveShopStatus(String stallId, String status) async {
    try {
      return await prefs.setString('shop_status_$stallId', status);
    } catch (e) {
      AppLogger.error('Error saving shop status', e);
      return false;
    }
  }

  /// Get shop status by ID
  String? getShopStatus(String stallId) {
    try {
      return prefs.getString('shop_status_$stallId');
    } catch (e) {
      AppLogger.error('Error getting shop status', e);
      return null;
    }
  }

  // ==================== User Data Management ====================

  /// Save user data
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      return await prefs.setString(AppConfig.userKey, jsonString);
    } catch (e) {
      AppLogger.error('Error saving user data', e);
      return false;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = prefs.getString(AppConfig.userKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user data', e);
      return null;
    }
  }

  /// Remove user data
  Future<bool> removeUserData() async {
    try {
      return await prefs.remove(AppConfig.userKey);
    } catch (e) {
      AppLogger.error('Error removing user data', e);
      return false;
    }
  }

  // ==================== Saved Menu Plans ====================

  Future<bool> saveMenuPlans(List<SavedMenuCollection> plans) async {
    try {
      final jsonString = jsonEncode(
        plans.map((item) => item.toJson()).toList(),
      );
      return await prefs.setString(_savedMenuPlansKey, jsonString);
    } catch (e) {
      AppLogger.error('Error saving menu plans', e);
      return false;
    }
  }

  List<SavedMenuCollection> getSavedMenuPlans() {
    try {
      final jsonString = prefs.getString(_savedMenuPlansKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedMenuCollection.fromJson)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting menu plans', e);
      return [];
    }
  }

  Future<bool> deleteSavedMenuPlan(String localId) async {
    try {
      final plans = getSavedMenuPlans();
      plans.removeWhere((item) => item.localId == localId);
      return await saveMenuPlans(plans);
    } catch (e) {
      AppLogger.error('Error deleting menu plan', e);
      return false;
    }
  }

  // ==================== Generic Storage Methods ====================

  /// Save string value
  Future<bool> setString(String key, String value) async {
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      AppLogger.error('Error saving string: $key', e);
      return false;
    }
  }

  /// Get string value
  String? getString(String key, {String? defaultValue}) {
    try {
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      AppLogger.error('Error getting string: $key', e);
      return defaultValue;
    }
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    try {
      return await prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('Error saving int: $key', e);
      return false;
    }
  }

  /// Get int value
  int? getInt(String key, {int? defaultValue}) {
    try {
      return prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      AppLogger.error('Error getting int: $key', e);
      return defaultValue;
    }
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    try {
      return await prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('Error saving bool: $key', e);
      return false;
    }
  }

  /// Get bool value
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      AppLogger.error('Error getting bool: $key', e);
      return defaultValue;
    }
  }

  /// Save double value
  Future<bool> setDouble(String key, double value) async {
    try {
      return await prefs.setDouble(key, value);
    } catch (e) {
      AppLogger.error('Error saving double: $key', e);
      return false;
    }
  }

  /// Get double value
  double? getDouble(String key, {double? defaultValue}) {
    try {
      return prefs.getDouble(key) ?? defaultValue;
    } catch (e) {
      AppLogger.error('Error getting double: $key', e);
      return defaultValue;
    }
  }

  /// Save list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await prefs.setStringList(key, value);
    } catch (e) {
      AppLogger.error('Error saving string list: $key', e);
      return false;
    }
  }

  /// Get list of strings
  List<String>? getStringList(String key) {
    try {
      return prefs.getStringList(key);
    } catch (e) {
      AppLogger.error('Error getting string list: $key', e);
      return null;
    }
  }

  /// Save object as JSON
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await prefs.setString(key, jsonString);
    } catch (e) {
      AppLogger.error('Error saving object: $key', e);
      return false;
    }
  }

  /// Get object from JSON
  Map<String, dynamic>? getObject(String key) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting object: $key', e);
      return null;
    }
  }

  /// Check if key exists
  bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      return await prefs.remove(key);
    } catch (e) {
      AppLogger.error('Error removing key: $key', e);
      return false;
    }
  }

  /// Clear all data
  Future<bool> clear() async {
    try {
      return await prefs.clear();
    } catch (e) {
      AppLogger.error('Error clearing storage', e);
      return false;
    }
  }

  /// Get all keys
  Set<String> getAllKeys() {
    return prefs.getKeys();
  }
}
