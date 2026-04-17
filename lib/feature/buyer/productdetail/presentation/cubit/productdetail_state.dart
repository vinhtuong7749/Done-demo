import 'package:equatable/equatable.dart';

/// State cho ProductDetail
class ProductDetailState extends Equatable {
  final String? maMonAn; // Mã món ăn để reload API
  final String productName;
  final String productImage;
  final String price;
  final String priceUnit;
  final double rating;
  final int soldCount;
  final String shopName;
  final String category;
  final String description;
  final List<Review> reviews;
  final int cartItemCount;
  final bool isFavorite;
  final bool isLoading;
  final String? errorMessage;

  // Thông tin chi tiết món ăn từ API
  final String? doKho;
  final int? khoangThoiGian;
  final int? khauPhanTieuChuan;
  final int currentKhauPhan; // Khẩu phần hiện tại (có thể điều chỉnh)
  final int? calories;
  final String? cachThucHien;
  final String? soChe;
  final String? cachDung;
  final List<NguyenLieuInfo>? nguyenLieu;
  final List<DanhMucInfo>? danhMuc;

  const ProductDetailState({
    this.maMonAn,
    this.productName = '',
    this.productImage = '',
    this.price = '',
    this.priceUnit = '',
    this.rating = 0.0,
    this.soldCount = 0,
    this.shopName = '',
    this.category = '',
    this.description = '',
    this.reviews = const [],
    this.cartItemCount = 0,
    this.isFavorite = false,
    this.isLoading = false,
    this.errorMessage,
    this.doKho,
    this.khoangThoiGian,
    this.khauPhanTieuChuan,
    this.currentKhauPhan = 1,
    this.calories,
    this.cachThucHien,
    this.soChe,
    this.cachDung,
    this.nguyenLieu,
    this.danhMuc,
  });

  ProductDetailState copyWith({
    String? maMonAn,
    String? productName,
    String? productImage,
    String? price,
    String? priceUnit,
    double? rating,
    int? soldCount,
    String? shopName,
    String? category,
    String? description,
    List<Review>? reviews,
    int? cartItemCount,
    bool? isFavorite,
    bool? isLoading,
    String? errorMessage,
    String? doKho,
    int? khoangThoiGian,
    int? khauPhanTieuChuan,
    int? currentKhauPhan,
    int? calories,
    String? cachThucHien,
    String? soChe,
    String? cachDung,
    List<NguyenLieuInfo>? nguyenLieu,
    List<DanhMucInfo>? danhMuc,
  }) {
    return ProductDetailState(
      maMonAn: maMonAn ?? this.maMonAn,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      shopName: shopName ?? this.shopName,
      category: category ?? this.category,
      description: description ?? this.description,
      reviews: reviews ?? this.reviews,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      doKho: doKho ?? this.doKho,
      khoangThoiGian: khoangThoiGian ?? this.khoangThoiGian,
      khauPhanTieuChuan: khauPhanTieuChuan ?? this.khauPhanTieuChuan,
      currentKhauPhan: currentKhauPhan ?? this.currentKhauPhan,
      calories: calories ?? this.calories,
      cachThucHien: cachThucHien ?? this.cachThucHien,
      soChe: soChe ?? this.soChe,
      cachDung: cachDung ?? this.cachDung,
      nguyenLieu: nguyenLieu ?? this.nguyenLieu,
      danhMuc: danhMuc ?? this.danhMuc,
    );
  }

  @override
  List<Object?> get props => [
    maMonAn,
    productName,
    productImage,
    price,
    priceUnit,
    rating,
    soldCount,
    shopName,
    category,
    description,
    reviews,
    cartItemCount,
    isFavorite,
    isLoading,
    errorMessage,
    doKho,
    khoangThoiGian,
    khauPhanTieuChuan,
    currentKhauPhan,
    calories,
    cachThucHien,
    soChe,
    cachDung,
    nguyenLieu,
    danhMuc,
  ];
}

/// Model cho thông tin nguyên liệu
class NguyenLieuInfo extends Equatable {
  final String? maNguyenLieu;
  final String ten;
  final String dinhLuong;
  final String? donVi;
  final String? hinhAnh;
  final double? gia;
  final String? donViBan;
  final String? nhomNguyenLieu;
  final List<GianHangSimple>? gianHang; // Danh sách gian hàng

  const NguyenLieuInfo({
    this.maNguyenLieu,
    required this.ten,
    required this.dinhLuong,
    this.donVi,
    this.hinhAnh,
    this.gia,
    this.donViBan,
    this.nhomNguyenLieu,
    this.gianHang,
  });

  /// Format giá hiển thị
  String? get giaDisplay {
    if (gia == null) return null;
    final formatted = gia!
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formattedđ${donViBan != null ? '/$donViBan' : ''}';
  }

  bool get isGiaVi {
    final normalized = '${nhomNguyenLieu ?? ''} ${donVi ?? ''}'
        .toLowerCase()
        .trim();
    return normalized.contains('gia vị') || normalized.contains('gia vi');
  }

  GianHangSimple? get preferredGianHang {
    if (gianHang == null || gianHang!.isEmpty) return null;

    for (final item in gianHang!) {
      if (item.isAvailable) return item;
    }
    for (final item in gianHang!) {
      if (item.isMoCua) return item;
    }
    return gianHang!.first;
  }

  bool get hasAvailableShop => preferredGianHang?.isAvailable ?? false;

  @override
  List<Object?> get props => [
    maNguyenLieu,
    ten,
    dinhLuong,
    donVi,
    hinhAnh,
    gia,
    donViBan,
    nhomNguyenLieu,
    gianHang,
  ];
}

/// Model đơn giản cho gian hàng
class GianHangSimple extends Equatable {
  final String? maGianHang;
  final String? tenGianHang;
  final String? maCho;
  final String? tinhTrang;
  final int? soLuongBan;

  const GianHangSimple({
    this.maGianHang,
    this.tenGianHang,
    this.maCho,
    this.tinhTrang,
    this.soLuongBan,
  });

  /// Kiểm tra gian hàng có đang mở cửa không
  bool get isMoCua => tinhTrang == 'dang_mo_cua' || tinhTrang == null;

  /// Nếu API không trả tồn kho thì xem như chưa rõ và vẫn cho phép hiển thị
  bool get conHang => soLuongBan == null || soLuongBan! > 0;

  bool get isAvailable => isMoCua && conHang;

  @override
  List<Object?> get props => [
    maGianHang,
    tenGianHang,
    maCho,
    tinhTrang,
    soLuongBan,
  ];
}

/// Kết quả thêm tất cả nguyên liệu vào giỏ hàng
class AddAllResult {
  final int success;
  final int failed;
  final List<String> errors;

  AddAllResult({
    required this.success,
    required this.failed,
    required this.errors,
  });
}

/// Model cho thông tin danh mục
class DanhMucInfo extends Equatable {
  final String ten;

  const DanhMucInfo({required this.ten});

  @override
  List<Object?> get props => [ten];
}

/// Model cho Review
class Review extends Equatable {
  final int stars;
  final int count;
  final double percentage;

  const Review({
    required this.stars,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [stars, count, percentage];
}
