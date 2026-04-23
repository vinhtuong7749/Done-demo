import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth/simple_auth_helper.dart';

/// Service để quản lý thông tin user profile
class UserProfileService {
  static const String _baseUrl = AppConfig.authBaseUrl;

  /// Lấy thông tin user hiện tại
  Future<UserProfileResponse> getProfile() async {
    print('👤 [PROFILE SERVICE] Fetching user profile...');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/me');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('👤 [PROFILE SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return UserProfileResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PROFILE SERVICE] Error: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin user
  Future<UserProfileResponse> updateProfile({
    required String tenNguoiDung,
    String? gioiTinh,
    String? sdt,
    String? diaChi,
    String? soTaiKhoan,
    String? nganHang,
    double? canNang,
    double? chieuCao,
  }) async {
    print('👤 [PROFILE SERVICE] Updating user profile...');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/profile');
      final body = json.encode({
        'user_name': tenNguoiDung,
        'gender': gioiTinh,
        'phone': sdt,
        'address': diaChi,
        'bank_account': soTaiKhoan,
        'bank_name': nganHang,
        'weight': canNang,
        'height': chieuCao,
      });

      debugPrint('👤 [USER PROFILE] PUT $url');
      debugPrint('👤 [USER PROFILE] Body: $body');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('👤 [PROFILE SERVICE] Response status: ${response.statusCode}');
      print('👤 [PROFILE SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return UserProfileResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to update profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PROFILE SERVICE] Error: $e');
      rethrow;
    }
  }
}

/// Model cho response profile
class UserProfileResponse {
  final UserProfileData data;

  UserProfileResponse({required this.data});

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      data: UserProfileData.fromJson(json['data'] ?? {}),
    );
  }
}

/// Model cho data profile
class UserProfileData {
  final String maNguoiDung;
  final String tenDangNhap;
  final String tenNguoiDung;
  final String vaiTro;
  final String? gioiTinh;
  final String? sdt;
  final String? diaChi;
  final String? soTaiKhoan;
  final String? nganHang;
  final double? canNang;
  final double? chieuCao;
  final String? walletId;

  UserProfileData({
    required this.maNguoiDung,
    required this.tenDangNhap,
    required this.tenNguoiDung,
    required this.vaiTro,
    this.gioiTinh,
    this.sdt,
    this.diaChi,
    this.soTaiKhoan,
    this.nganHang,
    this.canNang,
    this.chieuCao,
    this.walletId,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      maNguoiDung: (json['ma_nguoi_dung'] ?? json['user_id']) as String? ?? '',
      tenDangNhap: (json['ten_dang_nhap'] ?? json['login_name']) as String? ?? '',
      tenNguoiDung: (json['ten_nguoi_dung'] ?? json['user_name']) as String? ?? '',
      vaiTro: (json['vai_tro'] ?? json['role']) as String? ?? '',
      gioiTinh: json['gioi_tinh'] ?? json['gender'],
      sdt: json['sdt'] ?? json['phone'],
      diaChi: json['dia_chi'] ?? json['address'],
      soTaiKhoan: json['so_tai_khoan'] ?? json['bank_account'],
      nganHang: json['ngan_hang'] ?? json['bank_name'],
      canNang: _parseDouble(json['can_nang'] ?? json['weight']),
      chieuCao: _parseDouble(json['chieu_cao'] ?? json['height']),
      walletId: json['wallet_id'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Hiển thị giới tính
  String get gioiTinhDisplay {
    switch (gioiTinh) {
      case 'M':
        return 'Nam';
      case 'F':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }
}
