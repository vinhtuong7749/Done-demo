import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/gian_hang_service.dart';
import '../../../../core/services/cart_api_service.dart';
import '../../../../core/models/shop_detail_model.dart';
import '../../../../core/dependency/injection.dart';
import '../../../buyer/home/presentation/cubit/home_state.dart';

part 'shop_state.dart';

/// Shop Cubit quản lý logic nghiệp vụ của trang gian hàng
class ShopCubit extends Cubit<ShopState> {
  final GianHangService _gianHangService = getIt<GianHangService>();
  final CartApiService _cartApiService = CartApiService();

  String? _currentShopId;
  List<ShopProductPreview>? _suggestedProducts;

  ShopCubit() : super(ShopInitial());

  /// Tải thông tin cửa hàng và sản phẩm theo shopId
  Future<void> loadShop(String shopId, {List<ShopProductPreview>? suggestedProducts}) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [SHOP] Bắt đầu tải thông tin cửa hàng: $shopId');
      if (suggestedProducts != null && suggestedProducts.isNotEmpty) {
        AppLogger.info('   📌 Với ${suggestedProducts.length} sản phẩm được đề xuất từ chatbot');
      }
    }

    _currentShopId = shopId;
    _suggestedProducts = suggestedProducts;

    try {
      emit(ShopLoading());

      // Gọi API để lấy thông tin cửa hàng
      final response = await _gianHangService.getShopDetail(shopId);

      if (isClosed) return;

      // Convert API response to state models
      final shopInfo = _convertToShopInfo(response.detail);
      final apiProducts = _convertToShopProducts(response.sanPham.data, shopId);

      // Chuyển đổi sản phẩm đề xuất sang ShopProduct và kết hợp với sản phẩm từ API
      final allProducts = _mergeProductsWithSuggestions(apiProducts, shopId);

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [SHOP] Tải thành công: ${shopInfo.shopName}');
        AppLogger.info('   Sản phẩm đề xuất: ${_suggestedProducts?.length ?? 0}');
        AppLogger.info('   Sản phẩm từ API: ${apiProducts.length}');
        AppLogger.info('   Tổng sản phẩm hiển thị: ${allProducts.length}');
      }

      emit(ShopLoaded(
        shopInfo: shopInfo,
        products: allProducts,
        hasMore: response.sanPham.meta.hasNext,
        currentPage: response.sanPham.meta.page,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP] Lỗi khi tải cửa hàng: ${e.toString()}');
      }
      if (!isClosed) {
        emit(ShopFailure(
          errorMessage: 'Không thể tải thông tin cửa hàng: ${e.toString()}',
        ));
      }
    }
  }

  /// Convert ShopDetail từ API sang ShopInfo
  ShopInfo _convertToShopInfo(ShopDetail detail) {
    ShopChoInfo? choInfo;
    if (detail.cho != null) {
      choInfo = ShopChoInfo(
        maCho: detail.cho!.maCho,
        tenCho: detail.cho!.tenCho,
        diaChi: detail.cho!.diaChi,
        hinhAnh: detail.cho!.hinhAnh,
        phuong: detail.cho!.khuVuc?.phuong,
      );
    }

    return ShopInfo(
      shopId: detail.maGianHang,
      shopName: detail.tenGianHang,
      shopImage: detail.hinhAnh,
      shopRating: detail.danhGiaTb,
      productCount: detail.soSanPham,
      reviewCount: detail.soDanhGia,
      viTri: detail.viTri,
      ngayDangKy: detail.ngayDangKy,
      cho: choInfo,
    );
  }

  /// Convert danh sách sản phẩm từ API
  List<ShopProduct> _convertToShopProducts(
      List<ShopProductItem> items, String shopId) {
    return items.map((item) {
      return ShopProduct(
        productId: item.maNguyenLieu,
        productName: item.tenNguyenLieu,
        productImage: item.hinhAnh,
        price: item.giaCuoi,
        originalPrice: item.giaGoc,
        unit: item.donVi,
        categoryId: item.maNhomNguyenLieu,
        categoryName: item.tenNhomNguyenLieu,
        soldCount: item.soLuongBan,
        discountPercent: item.phanTramGiamGia,
        shopId: shopId,
      );
    }).toList();
  }

  /// Kết hợp sản phẩm đề xuất với sản phẩm từ API
  /// Đẩy sản phẩm đề xuất lên đầu, sau đó là các sản phẩm khác (không trùng lặp)
  List<ShopProduct> _mergeProductsWithSuggestions(List<ShopProduct> apiProducts, String shopId) {
    if (_suggestedProducts == null || _suggestedProducts!.isEmpty) {
      if (AppConfig.enableApiLogging) {
        AppLogger.info('📌 [SHOP] Không có sản phẩm đề xuất, hiển thị sản phẩm API');
      }
      return apiProducts;
    }

    // Chuyển đổi sản phẩm đề xuất sang ShopProduct
    final suggestedShopProducts = _suggestedProducts!.map((preview) {
      return ShopProduct(
        productId: '', // Không có ID từ chatbot, sẽ lấy từ API khi match
        productName: preview.productName,
        productImage: preview.productImage,
        price: preview.price,
        originalPrice: preview.price,
        unit: preview.unit,
        categoryId: '',
        categoryName: '',
        soldCount: 0,
        discountPercent: preview.discountPercent,
        shopId: shopId,
      );
    }).toList();

    // Tạo set tên sản phẩm đề xuất để loại bỏ trùng lặp
    final suggestedNames = _suggestedProducts!
        .map((p) => _normalizeName(p.productName))
        .toSet();

    // Lọc sản phẩm từ API, loại bỏ những sản phẩm đã có trong đề xuất
    final nonSuggestedApiProducts = apiProducts.where((product) {
      return !suggestedNames.contains(_normalizeName(product.productName));
    }).toList();

    // Cập nhật productId cho sản phẩm đề xuất từ API (nếu tìm thấy match)
    final updatedSuggestedProducts = suggestedShopProducts.map((suggested) {
      final matchingApiProduct = apiProducts.firstWhere(
        (api) => _normalizeName(api.productName) == _normalizeName(suggested.productName),
        orElse: () => suggested,
      );
      // Nếu tìm thấy match trong API, dùng dữ liệu từ API (có đầy đủ thông tin hơn)
      return matchingApiProduct.productId.isNotEmpty ? matchingApiProduct : suggested;
    }).toList();

    if (AppConfig.enableApiLogging) {
      AppLogger.info('✅ [SHOP] Đẩy ${updatedSuggestedProducts.length} sản phẩm đề xuất lên đầu');
      AppLogger.info('   Sản phẩm khác: ${nonSuggestedApiProducts.length}');
      if (updatedSuggestedProducts.isNotEmpty) {
        AppLogger.info('   Đề xuất: ${updatedSuggestedProducts.map((p) => p.productName).join(", ")}');
      }
    }

    // Ghép lại: sản phẩm đề xuất trước, sau đó là các sản phẩm khác
    return [...updatedSuggestedProducts, ...nonSuggestedApiProducts];
  }

  /// Chuẩn hóa tên sản phẩm để so sánh (lowercase + trim + remove extra spaces)
  String _normalizeName(String name) {
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');  }

  /// Tải thêm sản phẩm (phân trang)
  Future<void> loadMore() async {
    if (state is! ShopLoaded || _currentShopId == null) return;

    final currentState = state as ShopLoaded;
    if (!currentState.hasMore) return;

    if (AppConfig.enableApiLogging) {
      AppLogger.info('📄 [SHOP] Tải trang ${currentState.currentPage + 1}');
    }

    try {
      emit(ShopLoadingMore(
        shopInfo: currentState.shopInfo,
        products: currentState.products,
        selectedTabIndex: currentState.selectedTabIndex,
      ));

      // Gọi API với page tiếp theo
      final response = await _gianHangService.getShopDetail(
        _currentShopId!,
        page: currentState.currentPage + 1,
      );

      if (isClosed) return;

      // Convert và thêm vào danh sách hiện tại
      final newProducts = _convertToShopProducts(response.sanPham.data, _currentShopId!);
      final allProducts = [...currentState.products, ...newProducts];

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [SHOP] Tải thêm ${newProducts.length} sản phẩm');
        AppLogger.info('   Tổng: ${allProducts.length}/${response.sanPham.meta.total}');
      }

      emit(ShopLoaded(
        shopInfo: currentState.shopInfo,
        products: allProducts,
        selectedTabIndex: currentState.selectedTabIndex,
        hasMore: response.sanPham.meta.hasNext,
        currentPage: response.sanPham.meta.page,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP] Lỗi khi tải thêm: ${e.toString()}');
      }
      // Trả về state cũ nếu lỗi
      if (!isClosed) {
        emit(ShopLoaded(
          shopInfo: currentState.shopInfo,
          products: currentState.products,
          selectedTabIndex: currentState.selectedTabIndex,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      }
    }
  }

  /// Toggle yêu thích sản phẩm
  void toggleProductFavorite(String productId) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;

      final updatedProducts = currentState.products.map((product) {
        if (product.productId == productId) {
          if (AppConfig.enableApiLogging) {
            AppLogger.info(
                '❤️ [SHOP] Toggle yêu thích: $productId (${!product.isFavorite})');
          }
          return product.copyWith(isFavorite: !product.isFavorite);
        }
        return product;
      }).toList();

      emit(currentState.copyWith(products: updatedProducts));
    }
  }

  /// Chuyển đổi tab danh mục
  void selectCategory(int tabIndex) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;

      if (AppConfig.enableApiLogging) {
        AppLogger.info('📂 [SHOP] Chọn tab: $tabIndex');
      }

      emit(currentState.copyWith(selectedTabIndex: tabIndex));
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<bool> addToCart(String productId, int quantity) async {
    if (state is ShopLoaded && _currentShopId != null) {
      final currentState = state as ShopLoaded;
      final product =
          currentState.products.firstWhere((p) => p.productId == productId);

      if (AppConfig.enableApiLogging) {
        AppLogger.info(
            '🛒 [SHOP] Thêm vào giỏ hàng: ${product.productName} x$quantity');
      }

      try {
        await _cartApiService.addToCart(
          maNguyenLieu: productId,
          maGianHang: _currentShopId!,
          soLuong: quantity.toDouble(),
        );

        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [SHOP] Thêm giỏ hàng thành công');
        }
        return true;
      } catch (e) {
        if (AppConfig.enableApiLogging) {
          AppLogger.error('❌ [SHOP] Lỗi khi thêm giỏ hàng: $e');
        }
        return false;
      }
    }
    return false;
  }
}
