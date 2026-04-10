/// Model cho response của API giỏ hàng
class CartResponse {
  final bool success;
  final CartSummary cart;
  final List<CartItem> items;

  CartResponse({
    required this.success,
    required this.cart,
    required this.items,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('cart_id')) {
      final cartId = json['cart_id'];
      final totalAmount = _parseToDouble(json['total_amount']);
      final itemsList = (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ?? [];
              
      return CartResponse(
        success: true,
        cart: CartSummary(
          maDonHang: cartId,
          tongTien: totalAmount,
          tongTienGoc: totalAmount,
          tietKiem: 0,
          soMatHang: itemsList.length,
        ),
        items: itemsList,
      );
    }

    // API trả về nested cart object
    final cartData = json['cart'] as Map<String, dynamic>?;
    
    return CartResponse(
      success: json['success'] ?? false,
      cart: CartSummary(
        maDonHang: cartData?['ma_don_hang'] ?? cartData?['ma_gio_hang'] ?? '',
        tongTien: _parseToDouble(cartData?['tong_tien']),
        tongTienGoc: _parseToDouble(cartData?['tong_tien_goc']),
        tietKiem: _parseToDouble(cartData?['tiet_kiem']),
        soMatHang: _parseToInt(cartData?['so_mat_hang']),
      ),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  /// Parse value to int, handle both String and num
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse value to double, handle both String and num
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model cho thông tin tóm tắt giỏ hàng
class CartSummary {
  final String maDonHang;
  final double tongTien;
  final double tongTienGoc;
  final double tietKiem;
  final int soMatHang;

  CartSummary({
    required this.maDonHang,
    required this.tongTien,
    this.tongTienGoc = 0,
    this.tietKiem = 0,
    required this.soMatHang,
  });
}

/// Model cho item trong giỏ hàng
class CartItem {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String maGianHang;
  final String tenGianHang;
  final String maCho;
  final int soLuong;
  final double giaCuoi;
  final double thanhTien;
  final String? hinhAnh;

  CartItem({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    required this.maGianHang,
    required this.tenGianHang,
    required this.maCho,
    required this.soLuong,
    required this.giaCuoi,
    required this.thanhTien,
    this.hinhAnh,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      maNguyenLieu: json['ingredient_id'] ?? json['ma_nguyen_lieu'] ?? '',
      tenNguyenLieu: json['ingredient_name'] ?? json['ten_nguyen_lieu'] ?? '',
      maGianHang: json['stall_id'] ?? json['ma_gian_hang'] ?? '',
      tenGianHang: json['stall_name'] ?? json['ten_gian_hang'] ?? '',
      maCho: json['ma_cho'] ?? '',
      soLuong: _parseToInt(json['cart_quantity'] ?? json['so_luong']),
      giaCuoi: _parseToDouble(json['price'] ?? json['don_gia'] ?? json['gia_cuoi']),
      thanhTien: _parseToDouble(json['line_total'] ?? json['thanh_tien']),
      hinhAnh: json['hinh_anh'] ?? json['hinhAnh'] ?? json['product_image'],
    );
  }

  /// Parse value to int, handle both String and num
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse value to double, handle both String and num
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model cho response khi thêm vào giỏ hàng
class AddToCartResponse {
  final bool success;
  final String? maDonHang;
  final double? tongTien;
  final double? tongTienGoc;
  final double? tietKiem;
  final String? message;

  AddToCartResponse({
    required this.success,
    this.maDonHang,
    this.tongTien,
    this.tongTienGoc,
    this.tietKiem,
    this.message,
  });

  factory AddToCartResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('cart_id')) {
      return AddToCartResponse(
        success: true, // Nếu parse được CartResponse thì là AddToCart success
        maDonHang: json['cart_id'],
        tongTien: _parseToDouble(json['total_amount']),
        tongTienGoc: _parseToDouble(json['total_amount']),
        tietKiem: 0.0,
        message: 'Thêm vào giỏ hàng thành công',
      );
    }
    
    return AddToCartResponse(
      success: json['success'] ?? false,
      maDonHang: json['ma_don_hang'],
      tongTien: json['tong_tien'] != null ? _parseToDouble(json['tong_tien']) : null,
      tongTienGoc: json['tong_tien_goc'] != null ? _parseToDouble(json['tong_tien_goc']) : null,
      tietKiem: json['tiet_kiem'] != null ? _parseToDouble(json['tiet_kiem']) : null,
      message: json['message'],
    );
  }

  /// Parse value to double, handle both String and num
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model cho response khi checkout
/// Response format có thể là:
/// 1. Flat format:
/// { "success": true, "ma_don_hang": "DHABC123", "tong_tien": 30000, ... }
/// 
/// 2. Nested format:
/// { "success": true, "order": { "ma_don_hang": "DHABC123", ... }, "totals": { ... } }
class CheckoutResponse {
  final bool success;
  final String maDonHang;
  final String maThanhToan;
  final double tongTien;
  final int soMatHang;
  final int itemsCheckout;
  final int itemsRemaining;

  CheckoutResponse({
    required this.success,
    required this.maDonHang,
    required this.maThanhToan,
    required this.tongTien,
    required this.soMatHang,
    required this.itemsCheckout,
    required this.itemsRemaining,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ 3 format:
    // 1. Array format: { "orders": [{ "ma_don_hang": "...", ... }], "ma_thanh_toan": "..." }
    // 2. Nested format: { "order": { "ma_don_hang": "..." }, "totals": { ... } }
    // 3. Flat format: { "ma_don_hang": "...", ... }
    
    // Thêm hỗ trợ format 'data' phổ biến
    final data = json['data'] as List<dynamic>?;
    final orders = json['orders'] as List<dynamic>?;
    final order = json['order'] as Map<String, dynamic>?;
    final totals = json['totals'] as Map<String, dynamic>?;
    
    // Lấy ma_don_hang từ data[0] hoặc orders[0] hoặc order hoặc totals hoặc root
    String maDonHang = '';
    if (data != null && data.isNotEmpty) {
      final firstOrder = data[0] as Map<String, dynamic>;
      maDonHang = firstOrder['ma_don_hang'] ?? firstOrder['order_id'] ?? '';
    } else if (orders != null && orders.isNotEmpty) {
      final firstOrder = orders[0] as Map<String, dynamic>;
      maDonHang = firstOrder['ma_don_hang'] ?? '';
    } else {
      maDonHang = order?['ma_don_hang'] ?? 
                  totals?['ma_don_hang'] ?? 
                  json['ma_don_hang'] ?? '';
    }
    
    // Lấy ma_thanh_toan từ root hoặc data[0] hoặc orders[0] hoặc order
    String maThanhToan = json['ma_thanh_toan'] ?? '';
    if (maThanhToan.isEmpty && data != null && data.isNotEmpty) {
      final firstOrder = data[0] as Map<String, dynamic>;
      maThanhToan = firstOrder['ma_thanh_toan'] ?? '';
    }
    if (maThanhToan.isEmpty && orders != null && orders.isNotEmpty) {
      final firstOrder = orders[0] as Map<String, dynamic>;
      maThanhToan = firstOrder['ma_thanh_toan'] ?? '';
    }
    if (maThanhToan.isEmpty) {
      maThanhToan = order?['ma_thanh_toan'] ?? '';
    }
    
    // Đảm bảo maThanhToan không rỗng bằng cách fallback qua maDonHang nếu cần
    if (maThanhToan.isEmpty) {
      maThanhToan = maDonHang;
    }
    
    // Lấy tong_tien từ total_amount hoặc orders[0] hoặc order hoặc totals hoặc root
    dynamic tongTien;
    if (json['total_amount'] != null) {
      tongTien = json['total_amount'];
    } else if (orders != null && orders.isNotEmpty) {
      final firstOrder = orders[0] as Map<String, dynamic>;
      tongTien = firstOrder['tong_tien'];
    } else {
      tongTien = order?['tong_tien'] ?? 
                 totals?['tong_tien'] ?? 
                 json['tong_tien'];
    }
    
    return CheckoutResponse(
      success: json['success'] ?? false,
      maDonHang: maDonHang,
      maThanhToan: maThanhToan,
      tongTien: _parseToDouble(tongTien),
      soMatHang: _parseToInt(json['so_mat_hang'] ?? json['total_orders']),
      itemsCheckout: _parseToInt(json['items_checkout']),
      itemsRemaining: _parseToInt(json['items_remaining']),
    );
  }

  /// Parse value to int, handle both String and num
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parse value to double, handle both String and num
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Model cho response khi xóa item khỏi giỏ hàng
class DeleteCartItemResponse {
  final bool success;
  final String? maDonHang;
  final double? tongTien;
  final double? tongTienGoc;
  final double? tietKiem;
  final String? message;

  DeleteCartItemResponse({
    required this.success,
    this.maDonHang,
    this.tongTien,
    this.tongTienGoc,
    this.tietKiem,
    this.message,
  });

  factory DeleteCartItemResponse.fromJson(Map<String, dynamic> json) {
    return DeleteCartItemResponse(
      success: json['success'] ?? false,
      maDonHang: json['ma_don_hang'],
      tongTien: json['tong_tien'] != null ? _parseToDouble(json['tong_tien']) : null,
      tongTienGoc: json['tong_tien_goc'] != null ? _parseToDouble(json['tong_tien_goc']) : null,
      tietKiem: json['tiet_kiem'] != null ? _parseToDouble(json['tiet_kiem']) : null,
      message: json['message'],
    );
  }

  /// Parse value to double, handle both String and num
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
