import 'package:flutter_bloc/flutter_bloc.dart';
import 'ingredient_state.dart';
import '../../../../../../core/services/gian_hang_service.dart';
import '../../../../../../core/services/danh_muc_nguyen_lieu_service.dart';
import '../../../../../../core/services/nguyen_lieu_service.dart';
import '../../../../../../core/dependency/injection.dart';
import '../../../../../../core/utils/price_formatter.dart';

/// Cubit quản lý state cho Ingredient Screen
class IngredientCubit extends Cubit<IngredientState> {
  GianHangService? _gianHangService;
  DanhMucNguyenLieuService? _danhMucNguyenLieuService;
  NguyenLieuService? _nguyenLieuService;

  IngredientCubit() : super(const IngredientInitial()) {
    try {
      _gianHangService = getIt<GianHangService>();
      _danhMucNguyenLieuService = getIt<DanhMucNguyenLieuService>();
      _nguyenLieuService = getIt<NguyenLieuService>();
    } catch (e) {
      print('⚠️ Services not registered, will use mock data');
    }
  }

  /// Load dữ liệu ban đầu - Tối ưu: song song hóa tất cả API calls
  Future<void> loadIngredientData() async {
    emit(const IngredientLoading());

    List<Category> categories = [];
    List<Category> additionalCategories = [];
    List<Product> products = [];
    List<String> shopNames = [];
    List<Shop> shops = [];
    String? selectedMarketMa;

    try {
      // ⚡ Song song hóa: Fetch categories, ingredients, và shops cùng lúc
      final results = await Future.wait([
        // 1. Fetch categories
        _fetchCategories(),
        // 2. Fetch ingredients
        _fetchIngredients(selectedMarketMa),
        // 3. Fetch shops (chỉ trang đầu)
        _fetchShopsFirstPage(),
      ]);

      // Parse kết quả categories
      final categoriesResult = results[0] as List<Category>;
      if (categoriesResult.length > 5) {
        categories = categoriesResult.sublist(0, 5);
        additionalCategories = categoriesResult.sublist(5);
      } else {
        categories = categoriesResult;
      }

      // Parse kết quả ingredients
      final ingredientResult = results[1] as Map<String, dynamic>;
      products = ingredientResult['products'] as List<Product>;
      shopNames = ingredientResult['shopNames'] as List<String>;

      // Parse kết quả shops
      final shopsResult = results[2] as Map<String, dynamic>;
      shops = shopsResult['shops'] as List<Shop>;
      final hasMoreShops = shopsResult['hasMore'] as bool;

      print('⚡ [IngredientCubit] Loaded in parallel: ${categories.length + additionalCategories.length} categories, ${products.length} products, ${shops.length} shops');

      emit(IngredientLoaded(
        categories: categories,
        additionalCategories: additionalCategories,
        shops: shops,
        products: products,
        shopNames: shopNames,
        selectedBottomNavIndex: 3,
        cartItemCount: 0,
        currentPage: 1,
        hasMoreProducts: true,
        isLoadingMore: false,
        selectedMarketMa: selectedMarketMa,
      ));

      // Load thêm shops ở background (không block UI)
      if (hasMoreShops) {
        _loadRemainingShops(shops);
      }
    } catch (e) {
      print('❌ [IngredientCubit] Error loading data: $e');
      // Fallback: emit với data rỗng
      emit(IngredientLoaded(
        categories: _getMockCategories(),
        additionalCategories: _getMockAdditionalCategories(),
        shops: const [],
        products: const [],
        shopNames: const [],
        selectedBottomNavIndex: 3,
        cartItemCount: 0,
        currentPage: 1,
        hasMoreProducts: false,
        isLoadingMore: false,
      ));
    }
  }

  /// Fetch categories từ API
  Future<List<Category>> _fetchCategories() async {
    try {
      if (_danhMucNguyenLieuService != null) {
        final response = await _danhMucNguyenLieuService!.getDanhMucNguyenLieuList(
          page: 1,
          limit: 20,
          sort: 'ten_nhom_nguyen_lieu',
          order: 'asc',
        );
        return response.data.map((danhMuc) {
          return Category(
            maNhomNguyenLieu: danhMuc.maNhomNguyenLieu,
            name: danhMuc.tenNhomNguyenLieu,
            imagePath: '',
          );
        }).toList();
      }
    } catch (e) {
      print('⚠️ Lỗi khi fetch danh mục: $e');
    }
    return _getMockCategories() + _getMockAdditionalCategories();
  }

  /// Fetch ingredients từ API
  Future<Map<String, dynamic>> _fetchIngredients(String? maCho) async {
    try {
      if (_nguyenLieuService != null) {
        final response = await _nguyenLieuService!.getNguyenLieuList(
          page: 1,
          limit: 12,
          sort: 'ten_nguyen_lieu',
          order: 'asc',
          maCho: maCho,
        );
        final products = response.data.map((nguyenLieu) {
          return Product(
            maNguyenLieu: nguyenLieu.maNguyenLieu,
            name: nguyenLieu.tenNguyenLieu,
            price: _formatPrice(nguyenLieu.giaCuoi, nguyenLieu.giaGoc),
            imagePath: _getImagePath(nguyenLieu.hinhAnh),
            shopName: nguyenLieu.tenNhomNguyenLieu,
            badge: _getBadgeText(nguyenLieu.soGianHang),
            hasDiscount: _hasDiscount(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
            originalPrice: _formatOriginalPrice(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
          );
        }).toList();
        final shopNames = response.data
            .map((nguyenLieu) => nguyenLieu.tenNhomNguyenLieu)
            .toSet()
            .toList();
        return {'products': products, 'shopNames': shopNames};
      }
    } catch (e) {
      print('⚠️ Lỗi khi fetch nguyên liệu: $e');
    }
    return {'products': <Product>[], 'shopNames': <String>[]};
  }

  /// Fetch shops trang đầu (nhanh, không block)
  Future<Map<String, dynamic>> _fetchShopsFirstPage() async {
    try {
      if (_gianHangService != null) {
        final response = await _gianHangService!.getGianHangList(
          page: 1,
          limit: 50,
          sort: 'ten_gian_hang',
          order: 'asc',
        );
        final shops = response.data.map((gianHang) {
          return Shop(
            id: gianHang.maGianHang,
            name: gianHang.tenGianHang,
            imagePath: _getValidImagePath(gianHang.hinhAnh),
            rating: gianHang.danhGiaTb > 0 ? gianHang.danhGiaTb.toStringAsFixed(1) : null,
            distance: gianHang.viTri,
          );
        }).toList();
        return {'shops': shops, 'hasMore': response.meta.hasNext};
      }
    } catch (e) {
      print('⚠️ Lỗi khi fetch gian hàng: $e');
    }
    return {'shops': <Shop>[], 'hasMore': false};
  }

  /// Load thêm shops ở background (không block UI)
  Future<void> _loadRemainingShops(List<Shop> initialShops) async {
    try {
      if (_gianHangService == null || state is! IngredientLoaded) return;
      
      List<Shop> allShops = List.from(initialShops);
      int currentPage = 2;
      
      while (true) {
        final nextResponse = await _gianHangService!.getGianHangList(
          page: currentPage,
          limit: 50,
          sort: 'ten_gian_hang',
          order: 'asc',
        );
        
        allShops.addAll(nextResponse.data.map((gianHang) {
          return Shop(
            id: gianHang.maGianHang,
            name: gianHang.tenGianHang,
            imagePath: _getValidImagePath(gianHang.hinhAnh),
            rating: gianHang.danhGiaTb > 0 ? gianHang.danhGiaTb.toStringAsFixed(1) : null,
            distance: gianHang.viTri,
          );
        }));
        
        if (!nextResponse.meta.hasNext) break;
        currentPage++;
      }
      
      if (!isClosed && state is IngredientLoaded) {
        emit((state as IngredientLoaded).copyWith(shops: allShops));
        print('✅ [Background] Loaded all ${allShops.length} shops');
      }
    } catch (e) {
      print('⚠️ Background shop loading failed: $e');
    }
  }

  /// Mock categories fallback
  List<Category> _getMockCategories() => [
    const Category(name: 'Rau củ', imagePath: 'assets/img/ingredient_category_rau_cu.png'),
    const Category(name: 'Trái cây', imagePath: 'assets/img/ingredient_category_trai_cay-2bc751.png'),
    const Category(name: 'Thịt', imagePath: 'assets/img/ingredient_category_thit.png'),
    const Category(name: 'Thuỷ sản', imagePath: 'assets/img/ingredient_category_thuy_san-42d575.png'),
    const Category(name: 'Bánh kẹo', imagePath: 'assets/img/ingredient_category_banh_keo-512c43.png'),
  ];

  List<Category> _getMockAdditionalCategories() => [
    const Category(name: 'Dưỡng thể', imagePath: 'assets/img/ingredient_category_duong_the.png'),
    const Category(name: 'Gia vị', imagePath: 'assets/img/ingredient_category_gia_vi-122bd9.png'),
    const Category(name: 'Sữa các loại', imagePath: 'assets/img/ingredient_category_sua-b32339.png'),
    const Category(name: 'Đồ uống', imagePath: 'assets/img/ingredient_category_do_uong.png'),
  ];

  /// Chọn khu vực (chưa load nguyên liệu, chờ chọn chợ)
  void selectRegion(String maKhuVuc, String tenKhuVuc) {
    if (state is IngredientLoaded) {
      final currentState = state as IngredientLoaded;
      emit(currentState.copyWith(
        selectedRegion: tenKhuVuc,
        selectedRegionMa: maKhuVuc,
        selectedMarket: null, // Reset chợ
        selectedMarketMa: null,
      ));
      print('🔍 [IngredientCubit] Selected region: $tenKhuVuc (Ma: $maKhuVuc)');
      
      // Có thể load shops theo khu vực nếu cần
      // _loadShopsByRegion(maKhuVuc);
    }
  }

  /// Load shops theo khu vực (optional - nếu API hỗ trợ filter theo khu vực)
  Future<void> _loadShopsByRegion(String maKhuVuc) async {
    if (state is! IngredientLoaded) return;
    
    final currentState = state as IngredientLoaded;
    
    try {
      if (_gianHangService != null) {
        List<Shop> shops = [];
        
        // Fetch tất cả shops
        final firstResponse = await _gianHangService!.getGianHangList(
          page: 1,
          limit: 50,
          sort: 'ten_gian_hang',
          order: 'asc',
        );
        
        shops = firstResponse.data.map((gianHang) {
          return Shop(
            id: gianHang.maGianHang,
            name: gianHang.tenGianHang,
            imagePath: _getValidImagePath(gianHang.hinhAnh),
            rating: gianHang.danhGiaTb > 0 ? gianHang.danhGiaTb.toStringAsFixed(1) : null,
            distance: gianHang.viTri,
          );
        }).toList();
        
        // Fetch thêm nếu còn
        if (firstResponse.meta.hasNext) {
          int currentPage = 2;
          while (true) {
            final nextResponse = await _gianHangService!.getGianHangList(
              page: currentPage,
              limit: 50,
              sort: 'ten_gian_hang',
              order: 'asc',
            );
            
            shops.addAll(nextResponse.data.map((gianHang) {
              return Shop(
                id: gianHang.maGianHang,
                name: gianHang.tenGianHang,
                imagePath: _getValidImagePath(gianHang.hinhAnh),
                rating: gianHang.danhGiaTb > 0 ? gianHang.danhGiaTb.toStringAsFixed(1) : null,
                distance: gianHang.viTri,
              );
            }));
            
            if (!nextResponse.meta.hasNext) break;
            currentPage++;
          }
        }
        
        emit(currentState.copyWith(shops: shops));
        print('✅ Loaded ${shops.length} shops for region: $maKhuVuc');
      }
    } catch (e) {
      print('⚠️ Lỗi khi fetch gian hàng theo khu vực: $e');
    }
  }

  /// Load nguyên liệu theo mã chợ (chỉ load lại products, giữ nguyên categories và shops)
  Future<void> loadIngredientsByMarket(String maCho, String tenCho) async {
    if (state is! IngredientLoaded) return;
    
    final currentState = state as IngredientLoaded;
    
    // Giữ nguyên categories và shops hiện tại, chỉ set loading cho products
    emit(currentState.copyWith(
      isLoadingMore: true, // Dùng isLoadingMore để hiển thị loading indicator
    ));

    // Fetch nguyên liệu theo mã chợ
    List<Product> products = [];
    List<String> shopNames = [];
    
    try {
      if (_nguyenLieuService != null) {
        print('🔍 [IngredientCubit] Fetching nguyen lieu for ma_cho: $maCho');
        final response = await _nguyenLieuService!.getNguyenLieuList(
          page: 1,
          limit: 12,
          sort: 'ten_nguyen_lieu',
          order: 'asc',
          maCho: maCho, // Filter theo mã chợ
        );
        
        products = response.data.map((nguyenLieu) {
          return Product(
            maNguyenLieu: nguyenLieu.maNguyenLieu,
            name: nguyenLieu.tenNguyenLieu,
            price: _formatPrice(nguyenLieu.giaCuoi, nguyenLieu.giaGoc),
            imagePath: _getImagePath(nguyenLieu.hinhAnh),
            shopName: nguyenLieu.tenNhomNguyenLieu,
            badge: _getBadgeText(nguyenLieu.soGianHang),
            hasDiscount: _hasDiscount(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
            originalPrice: _formatOriginalPrice(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
          );
        }).toList();
        
        shopNames = response.data
            .map((nguyenLieu) => nguyenLieu.tenNhomNguyenLieu)
            .toSet()
            .toList();
        
        print('✅ Fetched ${products.length} nguyên liệu for cho: $tenCho');
      }
    } catch (e) {
      print('❌ Lỗi khi fetch nguyên liệu theo chợ: $e');
    }

    // Cập nhật state với products mới, giữ nguyên categories và shops
    emit(currentState.copyWith(
      products: products,
      shopNames: shopNames,
      selectedMarket: tenCho,
      selectedMarketMa: maCho,
      currentPage: 1,
      hasMoreProducts: products.length >= 12,
      isLoadingMore: false,
    ));
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (state is! IngredientLoaded) return;
    
    final currentState = state as IngredientLoaded;
    
    // Nếu đang load hoặc không còn products, không làm gì
    if (currentState.isLoadingMore || !currentState.hasMoreProducts) {
      return;
    }

    // Set loading state
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      if (_nguyenLieuService != null) {
        final nextPage = currentState.currentPage + 1;
        
        final response = await _nguyenLieuService!.getNguyenLieuList(
          page: nextPage,
          limit: 12,
          sort: 'ten_nguyen_lieu',
          order: 'asc',
          maCho: currentState.selectedMarketMa, // Sử dụng mã chợ từ state
        );
        
        // Convert API data to Product model
        final newProducts = response.data.map((nguyenLieu) {
          return Product(
            maNguyenLieu: nguyenLieu.maNguyenLieu,
            name: nguyenLieu.tenNguyenLieu,
            price: _formatPrice(nguyenLieu.giaCuoi, nguyenLieu.giaGoc),
            imagePath: _getImagePath(nguyenLieu.hinhAnh),
            shopName: nguyenLieu.tenNhomNguyenLieu,
            badge: _getBadgeText(nguyenLieu.soGianHang),
            hasDiscount: _hasDiscount(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
            originalPrice: _formatOriginalPrice(nguyenLieu.giaGoc, nguyenLieu.giaCuoi),
          );
        }).toList();
        
        // Merge với products hiện tại
        final allProducts = [...currentState.products, ...newProducts];
        
        // Extract shop names
        final newShopNames = response.data
            .map((nguyenLieu) => nguyenLieu.tenNhomNguyenLieu)
            .toSet()
            .toList();
        final allShopNames = {...currentState.shopNames, ...newShopNames}.toList();
        
        print('✅ Loaded page $nextPage: ${newProducts.length} more products');
        
        // Update state với products mới
        emit(currentState.copyWith(
          products: allProducts,
          shopNames: allShopNames,
          currentPage: nextPage,
          hasMoreProducts: response.meta.hasNext,
          isLoadingMore: false,
        ));
      } else {
        throw Exception('NguyenLieuService not available');
      }
    } catch (e) {
      print('⚠️ Lỗi khi load more nguyên liệu: $e');
      // Reset loading state nếu lỗi
      emit(currentState.copyWith(
        isLoadingMore: false,
        hasMoreProducts: false, // Không thử load nữa nếu lỗi
      ));
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    if (state is IngredientLoaded) {
      final currentState = state as IngredientLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  /// Perform search
  void performSearch() {
    if (state is IngredientLoaded) {
      // Implement search logic here
      // For now, just keep the current state
    }
  }

  /// Refresh toàn bộ dữ liệu (pull-to-refresh)
  Future<void> refreshData() async {
    await loadIngredientData();
  }

  /// Select category
  void selectCategory(String categoryName) {
    // Navigate to category detail or filter products
  }

  /// Change bottom navigation index
  void changeBottomNavIndex(int index) {
    if (state is IngredientLoaded) {
      final currentState = state as IngredientLoaded;
      emit(currentState.copyWith(selectedBottomNavIndex: index));
    }
  }

  /// Navigate to filter
  void navigateToFilter() {
    // Navigation will be handled by screen
  }

  /// Buy product now - Navigate to ingredient detail to select shop and buy
  void buyNow(Product product) {
    // Không thể mua trực tiếp từ danh sách vì cần chọn gian hàng
    // Sẽ được xử lý ở UI - navigate đến trang chi tiết
    print('🛍️ [IngredientCubit] Buy now: ${product.name}');
  }

  /// Add to cart - Navigate to ingredient detail to select shop and add
  void addToCart(Product product) {
    // Không thể thêm trực tiếp từ danh sách vì cần chọn gian hàng
    // Sẽ được xử lý ở UI - navigate đến trang chi tiết
    print('🛒 [IngredientCubit] Add to cart: ${product.name}');
  }

  // ==================== Helper Methods ====================

  /// Format giá hiển thị (giá chính - hiển thị to)
  /// Nếu có giaCuoi thì hiển thị giaCuoi, không thì hiển thị giaGoc
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

  /// Format giá gốc (giá gạch ngang - hiển thị nhỏ)
  /// Luôn hiển thị giaGoc nếu có cả giaGoc và giaCuoi
  String? _formatOriginalPrice(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return null;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return null;
    return PriceFormatter.formatPrice(giaGoc);
  }

  /// Kiểm tra có discount không
  /// Có discount khi có cả giaGoc và giaCuoi
  bool _hasDiscount(double? giaGoc, String? giaCuoi) {
    if (giaGoc == null || giaGoc <= 0) return false;
    if (giaCuoi == null || giaCuoi.isEmpty || giaCuoi == 'null') return false;
    return true;
  }

  /// Lấy đường dẫn hình ảnh
  /// Nếu hinhAnh null hoặc empty, dùng ảnh mặc định
  String _getImagePath(String? hinhAnh) {
    if (hinhAnh == null || hinhAnh.isEmpty || hinhAnh == 'null') {
      return 'assets/img/ingredient_product_1.png';
    }
    
    // Kiểm tra xem có phải URL hợp lệ không
    if (hinhAnh.startsWith('http://') || hinhAnh.startsWith('https://')) {
      return hinhAnh;
    }
    
    // Nếu không phải URL, có thể là đường dẫn local, dùng ảnh mặc định
    return 'assets/img/ingredient_product_1.png';
  }

  /// Lấy đường dẫn hình ảnh hợp lệ (cho shop/gian hàng)
  /// Trả về null nếu không có ảnh hợp lệ để widget tự hiển thị placeholder
  String? _getValidImagePath(String? hinhAnh) {
    if (hinhAnh == null || hinhAnh.isEmpty || hinhAnh == 'null') {
      return null;
    }
    
    // Chỉ trả về nếu là URL hợp lệ
    if (hinhAnh.startsWith('http://') || hinhAnh.startsWith('https://')) {
      return hinhAnh;
    }
    
    return null;
  }

  /// Tạo badge text dựa trên số gian hàng
  String? _getBadgeText(int soGianHang) {
    if (soGianHang <= 0) {
      return null;
    }
    
    if (soGianHang == 1) {
      return '1 gian hàng';
    }
    
    return '$soGianHang gian hàng';
  }
}
