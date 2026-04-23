import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/market_info_model.dart';
import '../models/market_map_model.dart';
import '../models/seller_list_model.dart';
import 'auth/simple_auth_helper.dart';

/// Service để quản lý thông tin chợ cho market manager
class MarketManagerService {
  static const String _baseUrl = AppConfig.adminBaseUrl;

  /// Lấy thông tin chợ của market manager
  Future<MarketInfoResponse> getMarketInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/market');

      debugPrint('🏪 [MARKET MANAGER] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🏪 [MARKET MANAGER] Response: ${response.statusCode}');
      debugPrint('🏪 [MARKET MANAGER] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return MarketInfoResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load market info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [MARKET MANAGER] Error: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu sơ đồ chợ
  Future<MarketMapResponse> getMapData() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/map');

      debugPrint('🗺️ [MARKET MAP] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🗺️ [MARKET MAP] Response: ${response.statusCode}');
      debugPrint('🗺️ [MARKET MAP] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return MarketMapResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load map data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [MARKET MAP] Error: $e');
      rethrow;
    }
  }

  /// Cập nhật cấu hình grid sơ đồ chợ
  Future<bool> updateGridConfig({
    required int gridCellWidth,
    required int gridCellHeight,
    required int gridColumns,
    required int gridRows,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/grid-config');
      final body = json.encode({
        'grid_cell_width': gridCellWidth,
        'grid_cell_height': gridCellHeight,
        'grid_columns': gridColumns,
        'grid_rows': gridRows,
      });

      debugPrint('⚙️ [GRID CONFIG] PUT $uri');
      debugPrint('⚙️ [GRID CONFIG] Body: $body');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('⚙️ [GRID CONFIG] Response: ${response.statusCode}');
      debugPrint('⚙️ [GRID CONFIG] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData['success'] == true;
      } else {
        throw Exception('Failed to update grid config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [GRID CONFIG] Error: $e');
      rethrow;
    }
  }

  /// Cập nhật vị trí gian hàng trên sơ đồ
  Future<bool> updateStorePosition({
    required String maGianHang,
    required int gridRow,
    required int gridCol,
    int gridFloor = 1,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/map/$maGianHang');
      final body = json.encode({
        'grid_row': gridRow,
        'grid_col': gridCol,
        'grid_floor': gridFloor,
      });

      debugPrint('📍 [STORE POSITION] PUT $uri');
      debugPrint('📍 [STORE POSITION] Body: $body');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('📍 [STORE POSITION] Response: ${response.statusCode}');
      debugPrint('📍 [STORE POSITION] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData['success'] == true;
      } else {
        throw Exception('Failed to update store position: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [STORE POSITION] Error: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tiểu thương với phân trang
  Future<SellerListResponse> getSellers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/sellers?page=$page&limit=$limit');

      debugPrint('👥 [SELLERS] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('👥 [SELLERS] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return SellerListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load sellers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SELLERS] Error: $e');
      rethrow;
    }
  }

  /// Lấy danh sách người bán chờ duyệt (tự đăng ký, approval_status=0)
  Future<Map<String, dynamic>> getPendingSellers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse('$_baseUrl/pending-sellers').replace(queryParameters: queryParams);

      debugPrint('⏳ [PENDING SELLERS] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('⏳ [PENDING SELLERS] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'data': jsonData['data'] as List<dynamic>? ?? [],
          'meta': jsonData['meta'] ?? {'total': 0, 'total_pages': 1, 'page': 1},
        };
      } else {
        throw Exception('Failed to load pending sellers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [PENDING SELLERS] Error: $e');
      rethrow;
    }
  }

  /// Duyệt người bán (approval_status: 0 -> 1)
  Future<bool> approveSeller(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/approve-seller/$userId');

      debugPrint('✅ [APPROVE SELLER] PATCH $uri');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ [APPROVE SELLER] Response: ${response.statusCode}');
      debugPrint('✅ [APPROVE SELLER] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData['success'] == true;
      } else {
        throw Exception('Failed to approve seller: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [APPROVE SELLER] Error: $e');
      rethrow;
    }
  }

  /// Thêm tiểu thương mới
  Future<bool> addSeller({
    required String tenDangNhap,
    required String matKhau,
    required String tenNguoiDung,
    required String sdt,
    required String diaChi,
    required String gioiTinh,
    required String tenGianHang,
    required String viTri,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/sellers');
      final body = json.encode({
        'ten_dang_nhap': tenDangNhap,
        'mat_khau': matKhau,
        'ten_nguoi_dung': tenNguoiDung,
        'sdt': sdt,
        'dia_chi': diaChi,
        'gioi_tinh': gioiTinh,
        'ten_gian_hang': tenGianHang,
        'vi_tri': viTri,
      });

      debugPrint('➕ [ADD SELLER] POST $uri');
      debugPrint('➕ [ADD SELLER] Body: $body');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('➕ [ADD SELLER] Response: ${response.statusCode}');
      debugPrint('➕ [ADD SELLER] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData['success'] == true;
      } else {
        throw Exception('Failed to add seller: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [ADD SELLER] Error: $e');
      rethrow;
    }
  }

  /// Đăng ký gian hàng cho tiểu thương chờ tạo sạp
  Future<bool> registerStall({
    required String maNguoiDung,
    required String tenGianHang,
    required String stallLocation,
    required int gridCol,
    required int gridRow,
    int? gridFloor,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/dang-ky-gian-hang');
      final body = json.encode({
        'ma_nguoi_dung': maNguoiDung,
        'ten_gian_hang': tenGianHang,
        'stall_location': stallLocation,
        'grid_col': gridCol,
        'grid_row': gridRow,
        if (gridFloor != null) 'grid_floor': gridFloor,
      });

      debugPrint('🏪 [REGISTER STALL] POST $uri');
      debugPrint('🏪 [REGISTER STALL] Body: $body');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('🏪 [REGISTER STALL] Response: ${response.statusCode}');
      debugPrint('🏪 [REGISTER STALL] Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData['success'] == true;
      } else {
        throw Exception('Failed to register stall: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [REGISTER STALL] Error: $e');
      rethrow;
    }
  }
}
