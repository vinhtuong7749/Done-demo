import 'package:equatable/equatable.dart';
import '../../../../../../core/services/review_api_service.dart';

/// State cho IngredientDetail
class IngredientDetailState extends Equatable {
  final String? maNguyenLieu;
  final String ingredientName;
  final String ingredientImage;
  final String price;
  final String unit;
  final double rating;
  final int soldCount;
  final String shopName;
  final String description;
  final List<Seller> sellers; // Danh sách người bán
  final Seller? selectedSeller; // Gian hàng được chọn
  final int quantity; // Số lượng muốn mua
  final List<RelatedProduct> relatedProducts;
  final List<RelatedProduct> recommendedProducts;
  final int cartItemCount;
  final bool isFavorite;
  final bool isLoading;
  final String? errorMessage;
  // Reviews
  final List<StoreReviewItem> reviews;
  final int totalReviews;
  final double avgRating;
  final bool isLoadingReviews;
  final bool isAddingToCart;
  final String? lastCartActionMessage;
  final bool? lastCartActionSuccess;

  const IngredientDetailState({
    this.maNguyenLieu,
    this.ingredientName = '',
    this.ingredientImage = '',
    this.price = '',
    this.unit = 'Ký',
    this.rating = 0.0,
    this.soldCount = 0,
    this.shopName = '',
    this.description = '',
    this.sellers = const [],
    this.selectedSeller,
    this.quantity = 1,
    this.relatedProducts = const [],
    this.recommendedProducts = const [],
    this.cartItemCount = 0,
    this.isFavorite = false,
    this.isLoading = false,
    this.errorMessage,
    // Reviews
    this.reviews = const [],
    this.totalReviews = 0,
    this.avgRating = 0.0,
    this.isLoadingReviews = false,
    this.isAddingToCart = false,
    this.lastCartActionMessage,
    this.lastCartActionSuccess,
  });

  IngredientDetailState copyWith({
    String? maNguyenLieu,
    String? ingredientName,
    String? ingredientImage,
    String? price,
    String? unit,
    double? rating,
    int? soldCount,
    String? shopName,
    String? description,
    List<Seller>? sellers,
    Object? selectedSeller = _undefined, // Sử dụng sentinel value
    int? quantity,
    List<RelatedProduct>? relatedProducts,
    List<RelatedProduct>? recommendedProducts,
    int? cartItemCount,
    bool? isFavorite,
    bool? isLoading,
    String? errorMessage,
    // Reviews
    List<StoreReviewItem>? reviews,
    int? totalReviews,
    double? avgRating,
    bool? isLoadingReviews,
    bool? isAddingToCart,
    String? lastCartActionMessage,
    bool? lastCartActionSuccess,
  }) {
    return IngredientDetailState(
      maNguyenLieu: maNguyenLieu ?? this.maNguyenLieu,
      ingredientName: ingredientName ?? this.ingredientName,
      ingredientImage: ingredientImage ?? this.ingredientImage,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      sellers: sellers ?? this.sellers,
      selectedSeller: selectedSeller == _undefined
          ? this.selectedSeller
          : selectedSeller as Seller?,
      quantity: quantity ?? this.quantity,
      relatedProducts: relatedProducts ?? this.relatedProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      // Reviews
      reviews: reviews ?? this.reviews,
      totalReviews: totalReviews ?? this.totalReviews,
      avgRating: avgRating ?? this.avgRating,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
      isAddingToCart: isAddingToCart ?? this.isAddingToCart,
      lastCartActionMessage: lastCartActionMessage, // Luôn reset hoặc set mới
      lastCartActionSuccess: lastCartActionSuccess, // Luôn reset hoặc set mới
    );
  }

  @override
  List<Object?> get props => [
    maNguyenLieu,
    ingredientName,
    ingredientImage,
    price,
    unit,
    rating,
    soldCount,
    shopName,
    description,
    sellers,
    selectedSeller,
    quantity,
    relatedProducts,
    recommendedProducts,
    cartItemCount,
    isFavorite,
    isLoading,
    errorMessage,
    // Reviews
    reviews,
    totalReviews,
    avgRating,
    isLoadingReviews,
    isAddingToCart,
    lastCartActionMessage,
    lastCartActionSuccess,
  ];
}

// Sentinel value để phân biệt "không truyền" vs "truyền null"
const _undefined = Object();

/// Model cho người bán (seller) trong state
class Seller extends Equatable {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String price;
  final String? originalPrice;
  final bool hasDiscount;
  final String? imagePath;
  final int soLuongBan; // Số lượng: > 0 còn hàng, <= 0 hết hàng
  final String? unit;
  final String tinhTrang; // "dang_mo_cua" hoặc "tam_nghi"

  const Seller({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.price,
    this.originalPrice,
    this.hasDiscount = false,
    this.imagePath,
    required this.soLuongBan,
    this.unit,
    this.tinhTrang = 'dang_mo_cua',
  });

  /// Kiểm tra còn hàng không (so_luong_ban > 0 = còn hàng)
  bool get conHang => soLuongBan > 0;

  /// Kiểm tra gian hàng có đang mở cửa không
  bool get isMoCua => tinhTrang == 'dang_mo_cua';

  bool get isAvailable => isMoCua && conHang;

  @override
  List<Object?> get props => [
    maGianHang,
    tenGianHang,
    viTri,
    price,
    originalPrice,
    hasDiscount,
    imagePath,
    soLuongBan,
    unit,
    tinhTrang,
  ];
}

/// Model cho sản phẩm liên quan
class RelatedProduct extends Equatable {
  final String? maNguyenLieu;
  final String name;
  final String price;
  final String imagePath;
  final String shopName;
  final int soldCount;
  final String? unit;

  const RelatedProduct({
    this.maNguyenLieu,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.shopName,
    required this.soldCount,
    this.unit,
  });

  @override
  List<Object?> get props => [
    maNguyenLieu,
    name,
    price,
    imagePath,
    shopName,
    soldCount,
    unit,
  ];
}
