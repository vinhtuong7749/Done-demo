import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ingredient_detail_state.dart';
import '../../../../../../core/services/nguyen_lieu_service.dart';
import '../../../../../../core/services/review_api_service.dart';
import '../../../../../../core/dependency/injection.dart';
import '../../../../../../core/utils/price_formatter.dart';
import '../../../../../../core/services/cart_api_service.dart';
import '../../../../../../core/widgets/cart_badge_icon.dart';
import '../../../../../../core/models/nguyen_lieu_model.dart';

/// Cubit quản lý state cho IngredientDetail
class IngredientDetailCubit extends Cubit<IngredientDetailState> {
  NguyenLieuService? _nguyenLieuService;
  final ReviewApiService _reviewService = ReviewApiService();

  IngredientDetailCubit() : super(const IngredientDetailState()) {
    try {
      _nguyenLieuService = getIt<NguyenLieuService>();
    } catch (e) {
      debugPrint('⚠️ NguyenLieuService not registered');
    }
  }

  /// Load thông tin chi tiết nguyên liệu từ API
  Future<void> loadIngredientDetails({
    String? maNguyenLieu,
    String? ingredientName,
    String? ingredientImage,
    String? price,
    String? unit,
    String? shopName,
  }) async {
    emit(state.copyWith(isLoading: true));

    // Nếu không có mã nguyên liệu, dùng mock data
    if (maNguyenLieu == null || maNguyenLieu.isEmpty) {
      _loadMockData(ingredientName, ingredientImage, price, unit, shopName);
      return;
    }

    try {
      if (_nguyenLieuService != null) {
        final response = await _nguyenLieuService!.getNguyenLieuDetail(maNguyenLieu);
        
        final detail = response.data;
        
        // Convert sellers từ API
        final sellers = response.sellers.data.map((seller) {
          return Seller(
            maGianHang: seller.maGianHang,
            tenGianHang: seller.tenGianHang,
            viTri: seller.viTri,
            price: _formatPrice(seller.giaCuoi, seller.giaGoc),
            originalPrice: _formatOriginalPrice(seller.giaGoc, seller.giaCuoi),
            hasDiscount: _hasDiscount(seller.giaGoc, seller.giaCuoi),
            imagePath: seller.hinhAnh,
            soLuongBan: seller.soLuongBan,
            unit: seller.donViBan,
            tinhTrang: seller.tinhTrang,
          );
        }).toList();
        
        // Tính tổng số lượng còn (chỉ tính những gian hàng còn hàng)
        final totalStock = sellers.where((s) => s.conHang).fold<int>(0, (sum, seller) => sum + seller.soLuongBan);
        
        // Lấy giá từ seller đầu tiên hoặc từ detail
        final displayPrice = sellers.isNotEmpty 
            ? sellers.first.price 
            : _formatPrice(detail.giaCuoi, detail.giaGoc);
        final displayUnit = sellers.isNotEmpty && sellers.first.unit != null
            ? sellers.first.unit!
            : (detail.donVi ?? 'Ký');
        
        debugPrint('✅ Loaded ingredient detail: ${detail.tenNguyenLieu} with ${sellers.length} sellers');
        
        final firstSeller = sellers.isNotEmpty ? sellers.first : null;
        
        emit(state.copyWith(
          maNguyenLieu: detail.maNguyenLieu,
          ingredientName: detail.tenNguyenLieu,
          ingredientImage: detail.hinhAnh ?? '',
          price: displayPrice,
          unit: displayUnit,
          shopName: detail.tenNhomNguyenLieu,
          soldCount: totalStock,
          sellers: sellers,
          selectedSeller: firstSeller,
          description: 'Có ${detail.soGianHang} gian hàng đang bán sản phẩm này',
          relatedProducts: const [],
          recommendedProducts: const [],
          isLoading: false,
        ));
        
        // Load reviews cho seller đầu tiên
        if (firstSeller != null) {
          loadReviewsForSeller(firstSeller.maGianHang);
        }
        
        // Load random products cho related và recommended
        _loadRandomProducts(detail.maNguyenLieu);
      } else {
        throw Exception('NguyenLieuService not available');
      }
    } catch (e) {
      print('⚠️ Lỗi khi fetch chi tiết nguyên liệu: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin nguyên liệu',
      ));
      // Fallback to mock data
      _loadMockData(ingredientName, ingredientImage, price, unit, shopName);
    }
  }

  /// Load mock data khi không có API
  void _loadMockData(String? ingredientName, String? ingredientImage, String? price, String? unit, String? shopName) {
    final relatedProducts = [
      const RelatedProduct(
        name: 'Cá diêu hồng',
        price: '94,000 đ / Ký',
        imagePath: 'assets/img/ingredient_detail_related_1.png',
        shopName: 'Cô Hồng',
        soldCount: 106,
      ),
      const RelatedProduct(
        name: 'Cá chét tươi',
        price: '80,000 đ / Ký',
        imagePath: 'assets/img/ingredient_detail_related_2.png',
        shopName: 'Cô Sen',
        soldCount: 16,
      ),
    ];

    emit(state.copyWith(
      ingredientName: ingredientName ?? '',
      ingredientImage: ingredientImage ?? '',
      price: price ?? '',
      unit: unit ?? 'Ký',
      shopName: shopName ?? 'Cô Hồng',
      rating: 4.8,
      soldCount: 59,
      description: 'Sản phẩm tươi ngon, được nhập khẩu trực tiếp từ các nông trại uy tín.',
      relatedProducts: relatedProducts,
      recommendedProducts: relatedProducts,
      isLoading: false,
    ));
  }

  // ==================== Helper Methods ====================

  String _formatPrice(String? giaCuoi, double? giaGoc) {
    // Ưu tiên giaCuoi
    if (giaCuoi != null && giaCuoi.isNotEmpty && giaCuoi != 'null') {
      final parsed = PriceFormatter.parsePrice(giaCuoi);
      if (parsed != null && parsed > 0) {
        return PriceFormatter.formatPrice(parsed);
      }
    }
    
    // Nếu không có giaCuoi, dùng giaGoc
    if (giaGoc != null && giaGoc > 0) {
      return PriceFormatter.formatPrice(giaGoc);
    }
    
    return '0đ';
  }

  String? _formatOriginalPrice(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return null;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return null;
    return PriceFormatter.formatPrice(giaGoc);
  }

  bool _hasDiscount(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return false;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return false;
    return true;
  }

  /// Toggle favorite status
  void toggleFavorite() {
    emit(state.copyWith(isFavorite: !state.isFavorite));
  }

  /// Add to cart
  Future<void> addToCart() async {
    final seller = state.selectedSeller;
    if (seller == null || state.maNguyenLieu == null) return;

    // KIỂM TRA TRẠNG THÁI GIAN HÀNG
    if (!seller.isMoCua) {
      emit(state.copyWith(
        lastCartActionSuccess: false,
        lastCartActionMessage: 'Gian hàng đang đóng cửa, không thể thêm vào giỏ hàng',
      ));
      // Reset status sau 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) emit(state.copyWith(lastCartActionSuccess: null, lastCartActionMessage: null));
      });
      return;
    }

    emit(state.copyWith(isAddingToCart: true));

    try {
      final cartApiService = CartApiService();
      final response = await cartApiService.addToCart(
        maNguyenLieu: state.maNguyenLieu!,
        maGianHang: seller.maGianHang,
        soLuong: state.quantity.toDouble(),
      );

      if (response.success) {
        // Refresh cart badge
        refreshCartBadge();
        
        emit(state.copyWith(
          isAddingToCart: false,
          cartItemCount: state.cartItemCount + state.quantity,
          lastCartActionSuccess: true,
          lastCartActionMessage: 'Đã thêm vào giỏ hàng thành công',
        ));
      } else {
        throw Exception(response.message ?? 'Không thể thêm vào giỏ hàng');
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Gian hàng đang đóng cửa')) {
        errorMsg = 'Gian hàng đang đóng cửa, không thể thêm vào giỏ hàng';
      }
      emit(state.copyWith(
        isAddingToCart: false,
        lastCartActionSuccess: false,
        lastCartActionMessage: errorMsg,
      ));
    }

    // Reset status sau 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) emit(state.copyWith(lastCartActionSuccess: null, lastCartActionMessage: null));
    });
  }

  /// Reset kết quả action giỏ hàng
  void clearCartActionMessage() {
    emit(state.copyWith(
      lastCartActionMessage: null,
      lastCartActionSuccess: null,
    ));
  }

  /// Update cart item count
  void updateCartItemCount(int count) {
    emit(state.copyWith(cartItemCount: count));
  }

  /// Buy now action - Chuyển thẳng sang trang thanh toán với thông tin sản phẩm
  void buyNow(BuildContext context) {
    print('🛍️ [BUY NOW] Starting...');
    
    if (state.maNguyenLieu == null || state.maNguyenLieu!.isEmpty) {
      print('⚠️ Không có mã nguyên liệu');
      return;
    }

    if (state.selectedSeller == null) {
      print('⚠️ Chưa chọn gian hàng nào');
      return;
    }

    print('🛍️ [BUY NOW] Navigating to payment with:');
    print('  - Nguyên liệu: ${state.ingredientName}');
    print('  - Mã: ${state.maNguyenLieu}');
    print('  - Gian hàng: ${state.selectedSeller!.tenGianHang}');
    print('  - Mã gian hàng: ${state.selectedSeller!.maGianHang}');
    print('  - Giá: ${state.price}');
    
    // Navigate to payment page với thông tin sản phẩm
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'isBuyNow': true,
        'maNguyenLieu': state.maNguyenLieu,
        'tenNguyenLieu': state.ingredientName,
        'maGianHang': state.selectedSeller!.maGianHang,
        'tenGianHang': state.selectedSeller!.tenGianHang,
        'hinhAnh': state.ingredientImage,
        'gia': state.price,
        'donVi': state.unit,
        'soLuong': state.quantity,
      },
    );
  }

  /// Chat with shop
  void chatWithShop() {
    // Implement chat logic
  }

  /// Select seller (chọn gian hàng để mua)
  void selectSeller(Seller seller) {
    debugPrint('🏪 [SELECT SELLER] Selecting: ${seller.maGianHang} - ${seller.tenGianHang}');
    
    // Cập nhật thông tin hiển thị và lưu seller được chọn
    emit(state.copyWith(
      selectedSeller: seller,
      price: seller.price,
      unit: seller.unit ?? state.unit,
      shopName: seller.tenGianHang,
      // Reset reviews khi đổi gian hàng
      reviews: const [],
      totalReviews: 0,
      avgRating: 0.0,
    ));
    
    debugPrint('✅ Đã chọn gian hàng: ${seller.tenGianHang} (${seller.maGianHang}) - ${seller.price}');
    
    // Load reviews cho gian hàng mới
    loadReviewsForSeller(seller.maGianHang);
  }

  /// Load đánh giá cho gian hàng được chọn
  Future<void> loadReviewsForSeller(String maGianHang) async {
    debugPrint('⭐ [REVIEWS] Loading reviews for shop: $maGianHang');
    
    emit(state.copyWith(isLoadingReviews: true));
    
    try {
      final response = await _reviewService.getStoreReviews(maGianHang);
      
      if (response.success) {
        debugPrint('✅ [REVIEWS] Loaded ${response.items.length} reviews, avg: ${response.avg}');
        emit(state.copyWith(
          reviews: response.items,
          totalReviews: response.total,
          avgRating: response.avg,
          isLoadingReviews: false,
        ));
      } else {
        debugPrint('⚠️ [REVIEWS] Failed to load reviews');
        emit(state.copyWith(
          reviews: const [],
          totalReviews: 0,
          avgRating: 0.0,
          isLoadingReviews: false,
        ));
      }
    } catch (e) {
      debugPrint('❌ [REVIEWS] Error loading reviews: $e');
      emit(state.copyWith(
        reviews: const [],
        totalReviews: 0,
        avgRating: 0.0,
        isLoadingReviews: false,
      ));
    }
  }

  /// Tăng số lượng
  void increaseQuantity() {
    final maxQuantity = state.selectedSeller?.soLuongBan ?? 999;
    if (state.quantity < maxQuantity) {
      emit(state.copyWith(quantity: state.quantity + 1));
      print('➕ Số lượng: ${state.quantity}');
    } else {
      emit(state.copyWith(
        errorMessage: 'Chỉ còn $maxQuantity sản phẩm',
      ));
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) emit(state.copyWith(errorMessage: null));
      });
    }
  }

  /// Giảm số lượng (tối thiểu là 1)
  void decreaseQuantity() {
    if (state.quantity > 1) {
      emit(state.copyWith(quantity: state.quantity - 1));
      print('➖ Số lượng: ${state.quantity}');
    }
  }

  /// Load random products từ API cho related và recommended
  Future<void> _loadRandomProducts(String currentMaNguyenLieu) async {
    if (_nguyenLieuService == null) return;
    
    try {
      debugPrint('🔄 [RANDOM] Loading random products...');
      
      // Fetch danh sách nguyên liệu từ API
      final response = await _nguyenLieuService!.getNguyenLieuList(
        page: 1,
        limit: 20, // Lấy 20 sản phẩm để random
        sort: 'ten_nguyen_lieu',
        order: 'asc',
        hinhAnh: true,
      );
      
      if (isClosed) return;
      
      // Lọc bỏ sản phẩm hiện tại
      final filteredProducts = response.data
          .where((p) => p.maNguyenLieu != currentMaNguyenLieu)
          .toList();
      
      // Shuffle để random
      filteredProducts.shuffle();
      
      // Lấy 6 sản phẩm đầu cho related, 6 sản phẩm sau cho recommended
      final relatedList = filteredProducts.take(6).toList();
      final recommendedList = filteredProducts.skip(6).take(6).toList();
      
      // Convert sang RelatedProduct
      final relatedProducts = relatedList.map((p) => RelatedProduct(
        maNguyenLieu: p.maNguyenLieu,
        name: p.tenNguyenLieu,
        price: _formatPriceFromModel(p),
        imagePath: p.hinhAnh ?? '',
        shopName: p.tenNhomNguyenLieu, // Dùng tên nhóm nguyên liệu
        soldCount: p.soGianHang, // Dùng số gian hàng
        unit: p.donVi,
      )).toList();
      
      final recommendedProducts = recommendedList.map((p) => RelatedProduct(
        maNguyenLieu: p.maNguyenLieu,
        name: p.tenNguyenLieu,
        price: _formatPriceFromModel(p),
        imagePath: p.hinhAnh ?? '',
        shopName: p.tenNhomNguyenLieu, // Dùng tên nhóm nguyên liệu
        soldCount: p.soGianHang, // Dùng số gian hàng
        unit: p.donVi,
      )).toList();
      
      debugPrint('✅ [RANDOM] Loaded ${relatedProducts.length} related, ${recommendedProducts.length} recommended');
      
      emit(state.copyWith(
        relatedProducts: relatedProducts,
        recommendedProducts: recommendedProducts,
      ));
    } catch (e) {
      debugPrint('❌ [RANDOM] Error loading random products: $e');
      // Không emit error, giữ nguyên state
    }
  }

  /// Format giá từ NguyenLieuModel
  String _formatPriceFromModel(NguyenLieuModel product) {
    // Ưu tiên giaCuoi
    if (product.giaCuoi != null) {
      final parsed = PriceFormatter.parsePrice(product.giaCuoi!);
      if (parsed != null && parsed > 0) {
        return PriceFormatter.formatPrice(parsed);
      }
    }
    
    // Nếu không có giaCuoi, dùng giaGoc
    if (product.giaGoc != null && product.giaGoc! > 0) {
      return PriceFormatter.formatPrice(product.giaGoc!);
    }
    
    return '0đ';
  }
}
