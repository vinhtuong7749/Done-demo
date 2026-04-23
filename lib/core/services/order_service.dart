import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth/simple_auth_helper.dart';
import '../utils/status_formatter.dart';

/// Service để fetch danh sách đơn hàng từ API
class OrderService {
  static const String _baseUrl = AppConfig.baseUrl;

  /// Huỷ đơn hàng
  Future<CancelOrderResponse> cancelOrder(String maDonHang) async {
    debugPrint('📦 [ORDER SERVICE] Cancelling order: $maDonHang');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/orders/$maDonHang');

      debugPrint('📦 [ORDER SERVICE] DELETE Request URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [ORDER SERVICE] Response status: ${response.statusCode}');
      debugPrint('📦 [ORDER SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return CancelOrderResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? 'Không thể huỷ đơn hàng');
      }
    } catch (e) {
      debugPrint('❌ [ORDER SERVICE] Cancel order error: $e');
      rethrow;
    }
  }

  /// Fetch chi tiết đơn hàng
  Future<OrderDetailResponse> getOrderDetail(String maDonHang) async {
    debugPrint('📦 [ORDER SERVICE] Fetching order detail: $maDonHang');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/orders/$maDonHang');

      debugPrint('📦 [ORDER SERVICE] Request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [ORDER SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return OrderDetailResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch order detail: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [ORDER SERVICE] Error: $e');
      rethrow;
    }
  }

  /// Fetch danh sách đơn hàng
  Future<OrderListResponse> getOrders({
    int page = 1,
    int limit = 12,
  }) async {
    debugPrint('📦 [ORDER SERVICE] Fetching orders (page $page, limit $limit)');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final buyerId = await getUserId();
      if (buyerId == null) {
        throw Exception('Buyer ID not found');
      }

      // API yêu cầu buyer_id và trailing slash giống cart API
      final url = Uri.parse('$_baseUrl/orders/').replace(
        queryParameters: {
          'buyer_id': buyerId,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      debugPrint('📦 [ORDER SERVICE] Request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📦 [ORDER SERVICE] Response status: ${response.statusCode}');
      debugPrint('📦 [ORDER SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return OrderListResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch orders: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [ORDER SERVICE] Error: $e');
      rethrow;
    }
  }

  /// Request Refund
  Future<Map<String, dynamic>> refundOrder(RefundRequest request) async {
    debugPrint('📦 [ORDER SERVICE] Requesting refund for order: ${request.orderId}');

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/buyer/refund');
      
      debugPrint('📦 [ORDER SERVICE] Request URL: $url');
      debugPrint('📦 [ORDER SERVICE] Payload: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📦 [ORDER SERVICE] Response status: ${response.statusCode}');
      debugPrint('📦 [ORDER SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData;
      } else {
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['detail'] ?? errorData['message'] ?? 'Không thể yêu cầu hoàn tiền');
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Lỗi hệ thống máy chủ (Mã lỗi: ${response.statusCode}). Vui lòng thử lại sau.');
          }
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ [ORDER SERVICE] Refund error: $e');
      rethrow;
    }
  }
}

class RefundRequest {
  final String orderId;
  final List<RefundItem> items;

  RefundRequest({required this.orderId, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class RefundItem {
  final String ingredientId;
  final String stallId;
  final String reason;

  RefundItem({
    required this.ingredientId,
    required this.stallId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'stall_id': stallId,
      'reason': reason,
    };
  }
}

/// Model cho response danh sách đơn hàng
class OrderListResponse {
  final bool success;
  final List<OrderModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  OrderListResponse({
    required this.success,
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      success: json['success'] ?? true,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderModel.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 12,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

/// Model cho đơn hàng
class OrderModel {
  final String maDonHang;
  final double tongTien;
  final DeliveryAddress? diaChiGiaoHang;
  final String tinhTrangDonHang;
  final DateTime? thoiGianGiaoHang;
  final String? maThanhToan;
  final PaymentInfo? thanhToan;

  OrderModel({
    required this.maDonHang,
    required this.tongTien,
    this.diaChiGiaoHang,
    required this.tinhTrangDonHang,
    this.thoiGianGiaoHang,
    this.maThanhToan,
    this.thanhToan,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse địa chỉ giao hàng từ JSON string
    DeliveryAddress? address;
    if (json['dia_chi_giao_hang'] != null) {
      try {
        final decoded = jsonDecode(json['dia_chi_giao_hang']);
        if (decoded is Map<String, dynamic>) {
          address = DeliveryAddress.fromJson(decoded);
        } else {
          debugPrint('Info: dia_chi_giao_hang is not a map: $decoded');
        }
      } catch (e) {
        debugPrint('Error parsing address: $e');
      }
    }

    return OrderModel(
      maDonHang: json['ma_don_hang'] ?? '',
      tongTien: _parseToDouble(json['tong_tien']),
      diaChiGiaoHang: address,
      tinhTrangDonHang: json['tinh_trang_don_hang'] ?? '',
      thoiGianGiaoHang: json['thoi_gian_giao_hang'] != null
          ? DateTime.tryParse(json['thoi_gian_giao_hang'])
          : null,
      maThanhToan: json['ma_thanh_toan'],
      thanhToan: json['thanh_toan'] != null
          ? PaymentInfo.fromJson(json['thanh_toan'])
          : null,
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Check trạng thái đơn hàng
  bool get isPending => tinhTrangDonHang == 'cho_xac_nhan';
  bool get isConfirmed => tinhTrangDonHang == 'da_xac_nhan';
  bool get isShipping => tinhTrangDonHang == 'dang_giao';
  bool get isDelivered => tinhTrangDonHang == 'da_giao';
  bool get isCancelled => tinhTrangDonHang == 'da_huy';

  /// Check trạng thái thanh toán
  bool get isPaid => thanhToan?.tinhTrangThanhToan == 'da_thanh_toan';
}

/// Model cho địa chỉ giao hàng
class DeliveryAddress {
  final String name;
  final String phone;
  final String address;

  DeliveryAddress({
    required this.name,
    required this.phone,
    required this.address,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

/// Model cho thông tin thanh toán
class PaymentInfo {
  final String maThanhToan;
  final String hinhThucThanhToan;
  final String tinhTrangThanhToan;
  final DateTime? thoiGianThanhToan;

  PaymentInfo({
    required this.maThanhToan,
    required this.hinhThucThanhToan,
    required this.tinhTrangThanhToan,
    this.thoiGianThanhToan,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      maThanhToan: json['ma_thanh_toan'] ?? '',
      hinhThucThanhToan: json['hinh_thuc_thanh_toan'] ?? '',
      tinhTrangThanhToan: json['tinh_trang_thanh_toan'] ?? '',
      thoiGianThanhToan: json['thoi_gian_thanh_toan'] != null
          ? DateTime.tryParse(json['thoi_gian_thanh_toan'])
          : null,
    );
  }

  String get paymentMethodDisplay {
    return StatusFormatter.formatPaymentMethod(hinhThucThanhToan);
  }

  String get paymentStatusDisplay {
    return StatusFormatter.formatOrderStatus(tinhTrangThanhToan);
  }
}


/// Model cho response chi tiết đơn hàng
class OrderDetailResponse {
  final bool success;
  final OrderDetailData data;

  OrderDetailResponse({
    required this.success,
    required this.data,
  });

  OrderDetailResponse copyWith({
    bool? success,
    OrderDetailData? data,
  }) {
    return OrderDetailResponse(
      success: success ?? this.success,
      data: data ?? this.data,
    );
  }

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailResponse(
      success: json['success'] ?? true,
      data: OrderDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

/// Model cho data chi tiết đơn hàng
class OrderDetailData {
  final String maDonHang;
  final String? maThanhToan;
  final String? maNguoiMua;
  final double tongTien;
  final DeliveryAddress? diaChiGiaoHang;
  final String tinhTrangDonHang;
  final DateTime? thoiGianGiaoHang;
  final PaymentInfo? thanhToan;
  final List<OrderItemDetail> items;

  OrderDetailData({
    required this.maDonHang,
    this.maThanhToan,
    this.maNguoiMua,
    required this.tongTien,
    this.diaChiGiaoHang,
    required this.tinhTrangDonHang,
    this.thoiGianGiaoHang,
    this.thanhToan,
    required this.items,
  });

  OrderDetailData copyWith({
    String? maDonHang,
    String? maThanhToan,
    String? maNguoiMua,
    double? tongTien,
    DeliveryAddress? diaChiGiaoHang,
    String? tinhTrangDonHang,
    DateTime? thoiGianGiaoHang,
    PaymentInfo? thanhToan,
    List<OrderItemDetail>? items,
  }) {
    return OrderDetailData(
      maDonHang: maDonHang ?? this.maDonHang,
      maThanhToan: maThanhToan ?? this.maThanhToan,
      maNguoiMua: maNguoiMua ?? this.maNguoiMua,
      tongTien: tongTien ?? this.tongTien,
      diaChiGiaoHang: diaChiGiaoHang ?? this.diaChiGiaoHang,
      tinhTrangDonHang: tinhTrangDonHang ?? this.tinhTrangDonHang,
      thoiGianGiaoHang: thoiGianGiaoHang ?? this.thoiGianGiaoHang,
      thanhToan: thanhToan ?? this.thanhToan,
      items: items ?? this.items,
    );
  }

  factory OrderDetailData.fromJson(Map<String, dynamic> json) {
    // Parse địa chỉ giao hàng từ JSON string
    DeliveryAddress? address;
    if (json['dia_chi_giao_hang'] != null) {
      try {
        final addressJson = jsonDecode(json['dia_chi_giao_hang']);
        address = DeliveryAddress.fromJson(addressJson);
      } catch (e) {
        debugPrint('Error parsing address: $e');
      }
    }

    return OrderDetailData(
      maDonHang: json['ma_don_hang'] ?? '',
      maThanhToan: json['ma_thanh_toan'],
      maNguoiMua: json['ma_nguoi_mua'],
      tongTien: _parseToDouble(json['tong_tien']),
      diaChiGiaoHang: address,
      tinhTrangDonHang: json['tinh_trang_don_hang'] ?? '',
      thoiGianGiaoHang: json['thoi_gian_giao_hang'] != null
          ? DateTime.tryParse(json['thoi_gian_giao_hang'])
          : null,
      thanhToan: json['thanh_toan'] != null
          ? PaymentInfo.fromJson(json['thanh_toan'])
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemDetail.fromJson(item))
              .toList() ??
          [],
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get orderStatusDisplay {
    return StatusFormatter.formatOrderStatus(tinhTrangDonHang);
  }
}

/// Model cho item trong chi tiết đơn hàng
class OrderItemDetail {
  final String maNguyenLieu;
  final String maGianHang;
  final int soLuong;
  final double giaCuoi;
  final double thanhTien;
  final String? maMonAn;
  final IngredientInfo? nguyenLieu;
  final ShopInfo? gianHang;
  final String? donViBan;
  final String? detailStatus;
  final String? cancelReason;

  OrderItemDetail({
    required this.maNguyenLieu,
    required this.maGianHang,
    required this.soLuong,
    required this.giaCuoi,
    required this.thanhTien,
    this.maMonAn,
    this.nguyenLieu,
    this.gianHang,
    this.donViBan,
    this.detailStatus,
    this.cancelReason,
  });

  OrderItemDetail copyWith({
    String? maNguyenLieu,
    String? maGianHang,
    int? soLuong,
    double? giaCuoi,
    double? thanhTien,
    String? maMonAn,
    IngredientInfo? nguyenLieu,
    ShopInfo? gianHang,
    String? donViBan,
    String? detailStatus,
    String? cancelReason,
  }) {
    return OrderItemDetail(
      maNguyenLieu: maNguyenLieu ?? this.maNguyenLieu,
      maGianHang: maGianHang ?? this.maGianHang,
      soLuong: soLuong ?? this.soLuong,
      giaCuoi: giaCuoi ?? this.giaCuoi,
      thanhTien: thanhTien ?? this.thanhTien,
      maMonAn: maMonAn ?? this.maMonAn,
      nguyenLieu: nguyenLieu ?? this.nguyenLieu,
      gianHang: gianHang ?? this.gianHang,
      donViBan: donViBan ?? this.donViBan,
      detailStatus: detailStatus ?? this.detailStatus,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      maGianHang: json['ma_gian_hang'] ?? '',
      soLuong: (json['so_luong'] as num?)?.toInt() ?? 0,
      giaCuoi: _parseToDouble(json['gia_cuoi']),
      thanhTien: _parseToDouble(json['thanh_tien']),
      maMonAn: json['ma_mon_an'],
      nguyenLieu: json['nguyen_lieu'] != null
          ? IngredientInfo.fromJson(json['nguyen_lieu'])
          : null,
      gianHang: json['gian_hang'] != null
          ? ShopInfo.fromJson(json['gian_hang'])
          : null,
      donViBan: json['don_vi_ban'],
      detailStatus: json['detail_status'],
      cancelReason: json['cancel_reason'],
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model cho thông tin nguyên liệu
class IngredientInfo {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String? hinhAnh;

  IngredientInfo({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    this.hinhAnh,
  });

  IngredientInfo copyWith({
    String? maNguyenLieu,
    String? tenNguyenLieu,
    String? donVi,
    String? hinhAnh,
  }) {
    return IngredientInfo(
      maNguyenLieu: maNguyenLieu ?? this.maNguyenLieu,
      tenNguyenLieu: tenNguyenLieu ?? this.tenNguyenLieu,
      donVi: donVi ?? this.donVi,
      hinhAnh: hinhAnh ?? this.hinhAnh,
    );
  }

  factory IngredientInfo.fromJson(Map<String, dynamic> json) {
    return IngredientInfo(
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      tenNguyenLieu: json['ten_nguyen_lieu'] ?? '',
      donVi: json['don_vi'],
      hinhAnh: json['hinh_anh'] ?? json['hinhAnh'],
    );
  }
}

/// Model cho thông tin gian hàng
class ShopInfo {
  final String maGianHang;
  final String tenGianHang;
  final String? viTri;
  final String? hinhAnh;

  ShopInfo({
    required this.maGianHang,
    required this.tenGianHang,
    this.viTri,
    this.hinhAnh,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      maGianHang: json['ma_gian_hang'] ?? '',
      tenGianHang: json['ten_gian_hang'] ?? '',
      viTri: json['vi_tri'],
      hinhAnh: json['hinh_anh'],
    );
  }
}


/// Model cho response huỷ đơn hàng
class CancelOrderResponse {
  final bool success;
  final String maDonHang;
  final List<RestoredItem> restoredItems;
  final int soMatHang;
  final String message;

  CancelOrderResponse({
    required this.success,
    required this.maDonHang,
    required this.restoredItems,
    required this.soMatHang,
    required this.message,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    return CancelOrderResponse(
      success: json['success'] ?? false,
      maDonHang: json['ma_don_hang'] ?? '',
      restoredItems: (json['restored_items'] as List<dynamic>?)
              ?.map((item) => RestoredItem.fromJson(item))
              .toList() ??
          [],
      soMatHang: json['so_mat_hang'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

/// Model cho item được khôi phục về giỏ hàng
class RestoredItem {
  final String maNguyenLieu;
  final String maGianHang;
  final int soLuong;

  RestoredItem({
    required this.maNguyenLieu,
    required this.maGianHang,
    required this.soLuong,
  });

  factory RestoredItem.fromJson(Map<String, dynamic> json) {
    return RestoredItem(
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      maGianHang: json['ma_gian_hang'] ?? '',
      soLuong: (json['so_luong'] as num?)?.toInt() ?? 0,
    );
  }
}
