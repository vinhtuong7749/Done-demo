import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/seller_order_model.dart';
import '../config/app_config.dart';
import 'auth/auth_service.dart';
import 'auth/simple_auth_helper.dart';

/// Service để quản lý đơn hàng của seller
class SellerOrderService {
  static const String _baseUrl = AppConfig.sellerBaseUrl;
  final AuthService _authService = AuthService();

  /// Lấy danh sách đơn hàng của seller
  Future<SellerOrdersResponse> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? maGianHang,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (maGianHang != null) 'ma_gian_hang': maGianHang,
      };

      // REMOVE trailing slash to avoid 404
      // Use join to ensure no double slashes or unwanted trailing slash
      String urlString = '$_baseUrl/orders';
      if (urlString.endsWith('/')) {
        urlString = urlString.substring(0, urlString.length - 1);
      }
      final uri = Uri.parse(urlString).replace(queryParameters: queryParams);
      
      debugPrint('📦 [SELLER ORDER] Request URI: ${uri.toString()}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [SELLER ORDER] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return SellerOrdersResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
        throw Exception('Phiên đăng nhập hết hạn');
      } else {
        debugPrint('❌ [SELLER ORDER] Failed body: ${response.body}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Error: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết đơn hàng
  Future<SellerOrderDetailResponse> getOrderDetail(String maDonHang) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/orders/$maDonHang');
      
      debugPrint('📦 [SELLER ORDER] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [SELLER ORDER] Detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return SellerOrderDetailResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load order detail: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Detail error: $e');
      rethrow;
    }
  }

  /// Xác nhận từng item trong đơn hàng
  /// API: PATCH /seller/orders/{order_id}/items/{ingredient_id}/confirm
  Future<bool> _confirmItem(String token, String orderId, String ingredientId) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/items/$ingredientId/confirm');
    debugPrint('📦 [SELLER ORDER] PATCH $uri');
    
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'action': 'da_duyet'}),
    );
    
    debugPrint('📦 [SELLER ORDER] Item confirm response: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
    return response.statusCode == 200;
  }

  /// Xác nhận đơn hàng (gọi confirm cho tất cả items)
  Future<ConfirmOrderResponse> confirmOrder(String maDonHang, {List<String> ingredientIds = const []}) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      if (ingredientIds.isEmpty) {
        // Thử lấy chi tiết đơn hàng để có danh sách ingredients
        try {
          final detail = await getOrderDetail(maDonHang);
          if (detail.data != null) {
            ingredientIds = detail.data!.chiTietDonHang
                .map((item) => item.maNguyenLieu)
                .where((id) => id.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('⚠️ [SELLER ORDER] Could not get order detail: $e');
        }
      }

      if (ingredientIds.isEmpty) {
        throw Exception('Không có sản phẩm nào trong đơn hàng để xác nhận');
      }

      debugPrint('📦 [SELLER ORDER] Confirming ${ingredientIds.length} items for order $maDonHang');
      
      bool allSuccess = true;
      for (final ingredientId in ingredientIds) {
        final success = await _confirmItem(token, maDonHang, ingredientId);
        if (!success) allSuccess = false;
      }

      return ConfirmOrderResponse(
        success: allSuccess,
        message: allSuccess ? 'Đã xác nhận đơn hàng thành công' : 'Một số sản phẩm không xác nhận được',
      );
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Confirm error: $e');
      rethrow;
    }
  }

  /// Lấy danh sách lý do từ chối
  Future<RejectionReasonsResponse> getRejectionReasons() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/rejection-reasons');
      
      debugPrint('📦 [SELLER ORDER] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [SELLER ORDER] Rejection reasons response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return RejectionReasonsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load rejection reasons: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Rejection reasons error: $e');
      rethrow;
    }
  }

  /// Từ chối đơn hàng
  Future<RejectOrderResponse> rejectOrder(String maDonHang, {required String reasonCode}) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse('$_baseUrl/orders/$maDonHang/reject');
      final requestBody = json.encode({'reason_code': reasonCode});
      
      debugPrint('📦 [SELLER ORDER] POST $uri');
      debugPrint('📦 [SELLER ORDER] Request body: $requestBody');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      debugPrint('📦 [SELLER ORDER] Reject response status: ${response.statusCode}');
      debugPrint('📦 [SELLER ORDER] Reject response body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('📦 [SELLER ORDER] Reject parsed: success=${jsonData['success']}, message=${jsonData['message']}');
        debugPrint('📦 [SELLER ORDER] Reject data: ${jsonData['data']}');
        return RejectOrderResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to reject order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Reject error: $e');
      rethrow;
    }
  }
}
