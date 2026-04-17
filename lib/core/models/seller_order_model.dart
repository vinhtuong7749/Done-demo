import 'dart:convert';
import '../config/app_config.dart';

/// Model cho đơn hàng của seller từ API
class SellerOrderModel {
  final String maDonHang;
  final double tongTien;
  final String tinhTrangDonHang;
  final DateTime? thoiGianGiaoHang;
  final DeliveryAddress? diaChiGiaoHang;
  final BuyerInfo? nguoiMua;
  final PaymentInfo? thanhToan;
  final List<OrderDetailItem> chiTietDonHang;

  SellerOrderModel({
    required this.maDonHang,
    required this.tongTien,
    required this.tinhTrangDonHang,
    this.thoiGianGiaoHang,
    this.diaChiGiaoHang,
    this.nguoiMua,
    this.thanhToan,
    required this.chiTietDonHang,
  });

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    // Parse địa chỉ giao hàng từ JSON string hoặc dùng N/A
    DeliveryAddress? address;
    final rawAddress = json['delivery_address'] ?? json['dia_chi_giao_hang'];
    if (rawAddress != null && rawAddress != 'N/A') {
      try {
        final addressJson = jsonDecode(rawAddress.toString());
        address = DeliveryAddress.fromJson(addressJson);
      } catch (_) {
        address = null;
      }
    }

    // Parse chi tiết đơn hàng (nguyen_lieu)
    final itemsList = (json['nguyen_lieu'] ?? json['chi_tiet_don_hang']) as List<dynamic>?;
    final items = itemsList?.map((e) => OrderDetailItem.fromJson(e as Map<String, dynamic>)).toList() ?? [];

    // Tính tổng tiền nếu không có sẵn
    double total = (json['tong_tien'] as num?)?.toDouble() ?? 
                   (json['total_price'] as num?)?.toDouble() ?? 
                   items.fold(0.0, (sum, item) => sum + item.thanhTien);

    return SellerOrderModel(
      maDonHang: (json['order_id'] ?? json['ma_don_hang'] ?? '').toString(),
      tongTien: total,
      tinhTrangDonHang: (json['order_status'] ?? json['tinh_trang_don_hang'] ?? '').toString(),
      thoiGianGiaoHang: json['delivery_time'] != null
          ? DateTime.tryParse(json['delivery_time'] as String)
          : (json['thoi_gian_giao_hang'] != null
              ? DateTime.tryParse(json['thoi_gian_giao_hang'] as String)
              : null),
      diaChiGiaoHang: address,
      nguoiMua: json['nguoi_mua'] != null
          ? (json['nguoi_mua'] is String 
              ? BuyerInfo(maNguoiMua: '', tenNguoiDung: json['nguoi_mua'] as String, sdt: '')
              : BuyerInfo.fromJson(json['nguoi_mua'] as Map<String, dynamic>))
          : null,
      thanhToan: json['thanh_toan'] != null
          ? PaymentInfo.fromJson(json['thanh_toan'] as Map<String, dynamic>)
          : null,
      chiTietDonHang: items,
    );
  }
}

/// Địa chỉ giao hàng
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
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

/// Thông tin người mua
class BuyerInfo {
  final String maNguoiMua;
  final String tenNguoiDung;
  final String sdt;

  BuyerInfo({
    required this.maNguoiMua,
    required this.tenNguoiDung,
    required this.sdt,
  });

  factory BuyerInfo.fromJson(Map<String, dynamic> json) {
    final nguoiDung = json['nguoi_dung'] as Map<String, dynamic>?;
    return BuyerInfo(
      maNguoiMua: json['ma_nguoi_mua'] as String? ?? '',
      tenNguoiDung: nguoiDung?['ten_nguoi_dung'] as String? ?? '',
      sdt: nguoiDung?['sdt'] as String? ?? '',
    );
  }
}

/// Thông tin thanh toán
class PaymentInfo {
  final String maThanhToan;
  final String hinhThucThanhToan;
  final String tinhTrangThanhToan;

  PaymentInfo({
    required this.maThanhToan,
    required this.hinhThucThanhToan,
    required this.tinhTrangThanhToan,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      maThanhToan: json['ma_thanh_toan'] as String? ?? '',
      hinhThucThanhToan: json['hinh_thuc_thanh_toan'] as String? ?? '',
      tinhTrangThanhToan: json['tinh_trang_thanh_toan'] as String? ?? '',
    );
  }

  /// Lấy text hiển thị cho hình thức thanh toán
  String get hinhThucText {
    switch (hinhThucThanhToan) {
      case 'tien_mat':
        return 'Tiền mặt';
      case 'chuyen_khoan':
        return 'Chuyển khoản';
      default:
        return hinhThucThanhToan;
    }
  }

  /// Lấy text hiển thị cho tình trạng thanh toán
  String get tinhTrangText {
    switch (tinhTrangThanhToan) {
      case 'chua_thanh_toan':
        return 'Chưa thanh toán';
      case 'da_thanh_toan':
        return 'Đã thanh toán';
      default:
        return tinhTrangThanhToan;
    }
  }

  /// Kiểm tra đã thanh toán chưa
  bool get daThanhToan => tinhTrangThanhToan == 'da_thanh_toan';
}

/// Chi tiết đơn hàng
class OrderDetailItem {
  final String maNguyenLieu;
  final String maGianHang;
  final int soLuong;
  final double giaCuoi;
  final double thanhTien;
  final String? maMonAn;
  final String tenNguyenLieu;
  final String? donVi;
  final String? hinhAnh;

  OrderDetailItem({
    required this.maNguyenLieu,
    required this.maGianHang,
    required this.soLuong,
    required this.giaCuoi,
    required this.thanhTien,
    this.maMonAn,
    required this.tenNguyenLieu,
    this.donVi,
    this.hinhAnh,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    // Parse mapping cho new API format (nguyen_lieu list)
    final maNguyenLieu = (json['ingredient_id'] ?? json['ma_nguyen_lieu'] ?? '').toString();
    final tenNL = (json['ingredient_name'] ?? '').toString();
    final soLuong = (json['quantity'] as num?)?.toInt() ?? (json['so_luong'] as num?)?.toInt() ?? 0;
    final gia = (json['price'] as num?)?.toDouble() ?? (json['gia_cuoi'] as num?)?.toDouble() ?? 0;
    
    // Parse từ san_pham_ban nếu có (old format)
    String finalTenNL = tenNL.isNotEmpty ? tenNL : maNguyenLieu;
    String? finalDonVi;
    String? finalHinhAnh;
    
    final sanPhamBan = json['san_pham_ban'] as Map<String, dynamic>?;
    if (sanPhamBan != null) {
      final nguyenLieu = sanPhamBan['nguyen_lieu'] as Map<String, dynamic>?;
      if (nguyenLieu != null) {
        finalTenNL = nguyenLieu['ten_nguyen_lieu'] as String? ?? finalTenNL;
        finalDonVi = nguyenLieu['don_vi'] as String?;
        finalHinhAnh = _parseImageUrl(nguyenLieu['hinh_anh'] ?? nguyenLieu['image']);
      }
    }

    return OrderDetailItem(
      maNguyenLieu: maNguyenLieu,
      maGianHang: (json['ma_gian_hang'] ?? '').toString(),
      soLuong: soLuong,
      giaCuoi: gia,
      thanhTien: (json['thanh_tien'] as num?)?.toDouble() ?? (soLuong * gia),
      maMonAn: json['ma_mon_an'] as String?,
      tenNguyenLieu: finalTenNL,
      donVi: finalDonVi,
      hinhAnh: finalHinhAnh,
    );
  }

  static String? _parseImageUrl(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final path = value.toString();
    if (path.startsWith('http')) return path;
    final baseUrl = AppConfig.imageBaseUrl;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}

/// Model chi tiết đơn hàng từ API detail
class SellerOrderDetailModel {
  final String maDonHang;
  final double tongTien;
  final String tinhTrangDonHang;
  final DateTime? thoiGianGiaoHang;
  final DeliveryAddress? diaChiGiaoHang;
  final BuyerInfo? nguoiMua;
  final PaymentInfo? thanhToan;
  final List<OrderDetailItem> chiTietDonHang;

  SellerOrderDetailModel({
    required this.maDonHang,
    required this.tongTien,
    required this.tinhTrangDonHang,
    this.thoiGianGiaoHang,
    this.diaChiGiaoHang,
    this.nguoiMua,
    this.thanhToan,
    required this.chiTietDonHang,
  });

  factory SellerOrderDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse địa chỉ giao hàng từ JSON string
    DeliveryAddress? address;
    if (json['dia_chi_giao_hang'] != null) {
      try {
        final addressJson = jsonDecode(json['dia_chi_giao_hang'] as String);
        address = DeliveryAddress.fromJson(addressJson);
      } catch (_) {
        address = null;
      }
    }

    return SellerOrderDetailModel(
      maDonHang: json['ma_don_hang'] as String,
      tongTien: (json['tong_tien'] as num).toDouble(),
      tinhTrangDonHang: json['tinh_trang_don_hang'] as String,
      thoiGianGiaoHang: json['thoi_gian_giao_hang'] != null
          ? DateTime.tryParse(json['thoi_gian_giao_hang'] as String)
          : null,
      diaChiGiaoHang: address,
      nguoiMua: json['nguoi_mua'] != null
          ? BuyerInfo.fromJson(json['nguoi_mua'] as Map<String, dynamic>)
          : null,
      thanhToan: json['thanh_toan'] != null
          ? PaymentInfo.fromJson(json['thanh_toan'] as Map<String, dynamic>)
          : null,
      chiTietDonHang: (json['chi_tiet_don_hang'] as List<dynamic>?)
              ?.map((e) => OrderDetailItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response từ API order detail
class SellerOrderDetailResponse {
  final bool success;
  final SellerOrderDetailModel? data;

  SellerOrderDetailResponse({
    required this.success,
    this.data,
  });

  factory SellerOrderDetailResponse.fromJson(Map<String, dynamic> json) {
    return SellerOrderDetailResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? SellerOrderDetailModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response từ API seller orders
class SellerOrdersResponse {
  final bool success;
  final List<SellerOrderModel> items;
  final PaginationInfo pagination;

  SellerOrdersResponse({
    required this.success,
    required this.items,
    required this.pagination,
  });

  factory SellerOrdersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final meta = json['meta'] as Map<String, dynamic>?;
    
    List<SellerOrderModel> items = [];
    if (rawData is List) {
      items = rawData.map((e) => SellerOrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (rawData is Map && rawData['items'] is List) {
      items = (rawData['items'] as List).map((e) => SellerOrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return SellerOrdersResponse(
      success: json['success'] as bool? ?? false,
      items: items,
      pagination: meta != null
          ? PaginationInfo.fromMetaJson(meta)
          : (rawData is Map && rawData['pagination'] != null 
              ? PaginationInfo.fromJson(rawData['pagination'] as Map<String, dynamic>)
              : PaginationInfo(page: 1, limit: 10, total: items.length, totalPages: 1)),
    );
  }
}

/// Thông tin phân trang
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  factory PaginationInfo.fromMetaJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Thông tin shipper được gán
class ShipperAssigned {
  final String maShipper;
  final String tenShipper;
  final String sdt;

  ShipperAssigned({
    required this.maShipper,
    required this.tenShipper,
    required this.sdt,
  });

  factory ShipperAssigned.fromJson(Map<String, dynamic> json) {
    return ShipperAssigned(
      maShipper: json['ma_shipper'] as String? ?? '',
      tenShipper: json['ten_shipper'] as String? ?? '',
      sdt: json['sdt'] as String? ?? '',
    );
  }
}

/// Response từ API confirm order
class ConfirmOrderResponse {
  final bool success;
  final String message;
  final String? maDonHang;
  final String? tinhTrangDonHang;
  final double? tongTien;
  final ShipperAssigned? shipperAssigned;

  ConfirmOrderResponse({
    required this.success,
    required this.message,
    this.maDonHang,
    this.tinhTrangDonHang,
    this.tongTien,
    this.shipperAssigned,
  });

  factory ConfirmOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return ConfirmOrderResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      maDonHang: (data?['order_id'] ?? data?['ma_don_hang'])?.toString(),
      tinhTrangDonHang: (data?['order_status'] ?? data?['tinh_trang_don_hang'])?.toString(),
      tongTien: (data?['total_price'] as num?)?.toDouble() ?? (data?['tong_tien'] as num?)?.toDouble(),
      shipperAssigned: data?['shipper_assigned'] != null
          ? ShipperAssigned.fromJson(data!['shipper_assigned'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Lý do từ chối đơn hàng
class RejectionReason {
  final String code;
  final String label;
  final String description;

  RejectionReason({
    required this.code,
    required this.label,
    required this.description,
  });

  factory RejectionReason.fromJson(Map<String, dynamic> json) {
    return RejectionReason(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Response từ API rejection reasons
class RejectionReasonsResponse {
  final bool success;
  final List<RejectionReason> reasons;

  RejectionReasonsResponse({
    required this.success,
    required this.reasons,
  });

  factory RejectionReasonsResponse.fromJson(Map<String, dynamic> json) {
    return RejectionReasonsResponse(
      success: json['success'] as bool? ?? false,
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((e) => RejectionReason.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Response từ API reject order
class RejectOrderResponse {
  final bool success;
  final String message;
  final String? maDonHang;
  final String? tinhTrangDonHang;
  final double? tongTien;
  final String? lyDoHuy;
  final String? reasonCode;
  final bool canHoanTien;

  RejectOrderResponse({
    required this.success,
    required this.message,
    this.maDonHang,
    this.tinhTrangDonHang,
    this.tongTien,
    this.lyDoHuy,
    this.reasonCode,
    this.canHoanTien = false,
  });

  factory RejectOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return RejectOrderResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      maDonHang: (data?['order_id'] ?? data?['ma_don_hang'])?.toString(),
      tinhTrangDonHang: (data?['order_status'] ?? data?['tinh_trang_don_hang'])?.toString(),
      tongTien: (data?['total_price'] as num?)?.toDouble() ?? (data?['tong_tien'] as num?)?.toDouble(),
      lyDoHuy: data?['ly_do_huy'] as String? ?? data?['ly_do'] as String?,
      reasonCode: data?['reason_code'] as String?,
      canHoanTien: data?['can_hoan_tien'] as bool? ?? false,
    );
  }
}
