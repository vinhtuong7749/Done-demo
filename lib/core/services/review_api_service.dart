import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Service để gọi API đánh giá
class ReviewApiService {
  // Backend review router đang nằm trực tiếp dưới /api
  String get _baseUrl {
    final base = AppConfig.baseUrl;
    if (base.endsWith('/api')) {
      return base;
    }
    return '$base/api';
  }

  /// Lấy token từ SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Lấy danh sách đánh giá theo gian hàng
  Future<StoreReviewsResponse> getStoreReviews(String maGianHang) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('⭐ [REVIEW API] Getting reviews for store: $maGianHang');
    }

    try {
      final url = Uri.parse('$_baseUrl/stores/$maGianHang/reviews');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (AppConfig.enableApiLogging) {
        AppLogger.info(
          '⭐ [REVIEW API] Response status: ${response.statusCode}',
        );
        AppLogger.info('⭐ [REVIEW API] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return StoreReviewsResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to get store reviews: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [REVIEW API] Get store reviews error: $e');
      }
      rethrow;
    }
  }

  /// Gửi đánh giá cho sản phẩm
  Future<ReviewResponse> submitReview({
    required String maDonHang,
    required String maNguyenLieu,
    required String maGianHang,
    required int rating,
    required String binhLuan,
  }) async {
    AppLogger.info('⭐ [REVIEW API] ========== START SUBMIT REVIEW ==========');
    AppLogger.info('⭐ [REVIEW API] Base URL: $_baseUrl');
    AppLogger.info('⭐ [REVIEW API] Full URL: $_baseUrl/reviews');
    AppLogger.info('⭐ [REVIEW API] maDonHang: $maDonHang');
    AppLogger.info('⭐ [REVIEW API] maNguyenLieu: $maNguyenLieu');
    AppLogger.info('⭐ [REVIEW API] maGianHang: $maGianHang');
    AppLogger.info('⭐ [REVIEW API] rating: $rating');
    AppLogger.info('⭐ [REVIEW API] binhLuan: $binhLuan');

    try {
      final token = await getToken();
      AppLogger.info(
        '⭐ [REVIEW API] Token: ${token != null ? "EXISTS (${token.substring(0, 20)}...)" : "NULL"}',
      );

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/reviews');
      AppLogger.info('⭐ [REVIEW API] Parsed URL: $url');

      final requestBody = {
        'ma_don_hang': maDonHang,
        'ma_nguyen_lieu': maNguyenLieu,
        'ma_gian_hang': maGianHang,
        'rating': rating,
        'binh_luan': binhLuan,
      };

      // In request body dạng JSON đẹp
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(requestBody);
      AppLogger.info('⭐ [REVIEW API] Request body (JSON):');
      AppLogger.info(prettyJson);
      AppLogger.info('⭐ [REVIEW API] Sending POST request...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      AppLogger.info('⭐ [REVIEW API] Response status: ${response.statusCode}');
      AppLogger.info('⭐ [REVIEW API] Response headers: ${response.headers}');
      AppLogger.info('⭐ [REVIEW API] Response body: ${response.body}');

      // Xử lý theo status code
      switch (response.statusCode) {
        case 200:
        case 201:
          final jsonData = json.decode(utf8.decode(response.bodyBytes));
          AppLogger.info('✅ [REVIEW API] Đánh giá thành công!');
          return ReviewResponse.fromJson(jsonData);

        case 403:
          AppLogger.error(
            '❌ [REVIEW API] 403 - Chỉ có thể đánh giá nguyên liệu trong đơn hàng đã giao của bạn',
          );
          throw ReviewException(
            statusCode: 403,
            message:
                'Chỉ có thể đánh giá nguyên liệu trong đơn hàng đã giao của bạn',
          );

        case 400:
          AppLogger.error('❌ [REVIEW API] 400 - Dữ liệu không hợp lệ');
          throw ReviewException(
            statusCode: 400,
            message: 'Dữ liệu đánh giá không hợp lệ',
          );

        case 401:
          AppLogger.error('❌ [REVIEW API] 401 - Chưa đăng nhập');
          throw ReviewException(
            statusCode: 401,
            message: 'Vui lòng đăng nhập để đánh giá',
          );

        case 404:
          AppLogger.error(
            '❌ [REVIEW API] 404 - Không tìm thấy đơn hàng hoặc nguyên liệu',
          );
          throw ReviewException(
            statusCode: 404,
            message: 'Không tìm thấy đơn hàng hoặc nguyên liệu',
          );

        case 409:
          AppLogger.error('❌ [REVIEW API] 409 - Đã đánh giá rồi');
          throw ReviewException(
            statusCode: 409,
            message: 'Bạn đã đánh giá sản phẩm này rồi',
          );

        default:
          AppLogger.error(
            '❌ [REVIEW API] ${response.statusCode} - Lỗi không xác định',
          );
          throw ReviewException(
            statusCode: response.statusCode,
            message: 'Lỗi gửi đánh giá: ${response.statusCode}',
          );
      }
    } on ReviewException {
      rethrow;
    } catch (e) {
      AppLogger.error('❌ [REVIEW API] Submit review error: $e');
      throw ReviewException(
        statusCode: 0,
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    } finally {
      AppLogger.info('⭐ [REVIEW API] ========== END SUBMIT REVIEW ==========');
    }
  }
}

/// Exception cho Review API
class ReviewException implements Exception {
  final int statusCode;
  final String message;

  ReviewException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

/// Model cho response khi gửi đánh giá
class ReviewResponse {
  final bool success;
  final ReviewData? review;
  final double? danhGiaTb;
  final String? message;

  ReviewResponse({
    required this.success,
    this.review,
    this.danhGiaTb,
    this.message,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      success: json['success'] ?? false,
      review: json['review'] != null
          ? ReviewData.fromJson(json['review'])
          : null,
      danhGiaTb: _parseToDouble(json['danh_gia_tb']),
      message: json['message'],
    );
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Model cho dữ liệu đánh giá
class ReviewData {
  final String maDanhGia;
  final String maDonHang;
  final String maNguyenLieu;
  final int rating;
  final String binhLuan;
  final DateTime? ngayDanhGia;

  ReviewData({
    required this.maDanhGia,
    required this.maDonHang,
    required this.maNguyenLieu,
    required this.rating,
    required this.binhLuan,
    this.ngayDanhGia,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      maDanhGia: json['ma_danh_gia'] ?? '',
      maDonHang: json['ma_don_hang'] ?? '',
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      rating: json['rating'] ?? 0,
      binhLuan: json['binh_luan'] ?? '',
      ngayDanhGia: json['ngay_danh_gia'] != null
          ? DateTime.tryParse(json['ngay_danh_gia'])
          : null,
    );
  }
}

/// Model cho response khi lấy danh sách đánh giá của gian hàng
class StoreReviewsResponse {
  final bool success;
  final int total;
  final double avg;
  final List<StoreReviewItem> items;

  StoreReviewsResponse({
    required this.success,
    required this.total,
    required this.avg,
    required this.items,
  });

  factory StoreReviewsResponse.fromJson(Map<String, dynamic> json) {
    return StoreReviewsResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      avg: _parseToDouble(json['avg']) ?? 0.0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => StoreReviewItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Model cho từng đánh giá của gian hàng
class StoreReviewItem {
  final String maDanhGia;
  final String? maDonHang;
  final String? maNguyenLieu;
  final int rating;
  final String binhLuan;
  final DateTime? ngayDanhGia;
  final ReviewerInfo? nguoiDanhGia;

  StoreReviewItem({
    required this.maDanhGia,
    this.maDonHang,
    this.maNguyenLieu,
    required this.rating,
    required this.binhLuan,
    this.ngayDanhGia,
    this.nguoiDanhGia,
  });

  factory StoreReviewItem.fromJson(Map<String, dynamic> json) {
    return StoreReviewItem(
      maDanhGia: json['ma_danh_gia'] ?? '',
      maDonHang: json['ma_don_hang'],
      maNguyenLieu: json['ma_nguyen_lieu'],
      rating: json['rating'] ?? 0,
      binhLuan: json['binh_luan'] ?? '',
      ngayDanhGia: json['ngay_danh_gia'] != null
          ? DateTime.tryParse(json['ngay_danh_gia'])
          : null,
      nguoiDanhGia: json['nguoi_danh_gia'] != null
          ? ReviewerInfo.fromJson(json['nguoi_danh_gia'])
          : null,
    );
  }
}

/// Model cho thông tin người đánh giá
class ReviewerInfo {
  final String maNguoiMua;
  final String tenHienThi;

  ReviewerInfo({required this.maNguoiMua, required this.tenHienThi});

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      maNguoiMua: json['ma_nguoi_mua'] ?? '',
      tenHienThi: json['ten_hien_thi'] ?? 'Người dùng',
    );
  }
}
