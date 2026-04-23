import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gian_hang_model.dart';
import '../models/shop_detail_model.dart';
import '../error/exceptions.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'auth/auth_service.dart';
import '../dependency/injection.dart';

/// Service để fetch danh sách gian hàng
class GianHangService {
  static const String baseUrl = AppConfig.buyerBaseUrl;
  final AuthService _authService = getIt<AuthService>();

  /// Lấy danh sách gian hàng
  ///
  /// Parameters:
  /// - page: Trang hiện tại (default: 1)
  /// - limit: Số lượng items per page (default: 12)
  /// - sort: Field để sort (default: 'ten_gian_hang')
  /// - order: Thứ tự sort 'asc' hoặc 'desc' (default: 'asc')
  Future<GianHangResponse> getGianHangList({
    int page = 1,
    int limit = 30,
    String sort = 'ten_gian_hang',
    String order = 'asc',
  }) async {
    try {
      final token = await _authService.getToken();

      final uri = Uri.parse('$baseUrl/gian-hang').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sort': sort,
          'order': order,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return GianHangResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
        throw UnauthorizedException('Phiên đăng nhập hết hạn');
      } else {
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ServerException) {
        rethrow;
      }
      throw NetworkException('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy chi tiết gian hàng theo mã
  /// API: GET /api/buyer/gian-hang/{ma_gian_hang}?page={page}
  Future<ShopDetailResponse> getShopDetail(String maGianHang, {int page = 1}) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [GIAN HANG] Fetching shop detail: $maGianHang (page: $page)');
    }

    try {
      final token = await _authService.getToken();

      final uri = Uri.parse('$baseUrl/gian-hang/$maGianHang').replace(
        queryParameters: {'page': page.toString()},
      );

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🏪 [GIAN HANG] URL: $uri');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🏪 [GIAN HANG] Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));

        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [GIAN HANG] Shop detail loaded successfully');
        }

        return ShopDetailResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
        throw UnauthorizedException('Phiên đăng nhập hết hạn');
      } else if (response.statusCode == 404) {
        throw ServerException('Không tìm thấy gian hàng');
      } else {
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [GIAN HANG] Error: $e');
      }
      if (e is UnauthorizedException || e is ServerException) {
        rethrow;
      }
      throw NetworkException('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Cập nhật trạng thái gian hàng (mo_cua / dong_cua)
  /// API: PATCH /api/seller/stall/status
  Future<bool> updateShopStatus(String status) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [GIAN HANG] Updating stall status to: $status');
    }

    try {
      final token = await _authService.getToken();
      final uri = Uri.parse('${AppConfig.baseUrl}/seller/stall/status');

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🏪 [GIAN HANG] Update status response: ${response.statusCode}');
        AppLogger.info('🏪 [GIAN HANG] Response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
        throw UnauthorizedException('Phiên đăng nhập hết hạn');
      } else {
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [GIAN HANG] Error updating status: $e');
      }
      rethrow;
    }
  }

  /// Kiểm tra người bán có gian hàng chưa
  /// API: GET /api/seller/stall/info
  Future<bool> checkSellerHasStall() async {
    try {
      final user = await _authService.getCurrentUser();
      
      if (AppConfig.enableApiLogging) {
        AppLogger.info('🏪 [STALL CHECK] User role: ${user.vaiTro}, stall_id: ${user.stallId}, approval: ${user.approvalStatus}');
      }

      // Đã duyệt (1) và có stallId
      return user.approvalStatus == 1 && user.stallId != null && user.stallId!.isNotEmpty;
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [STALL CHECK] Error: $e');
      }
      return true; // Mặc định cho vào để tránh chặn sai ứng dụng trong trường hợp lỗi mạng
    }
  }
}
