import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ingredient_cubit.dart';
import '../cubit/ingredient_state.dart';
import '../../../../../../core/widgets/ingredient_card.dart';
import '../../../../../../core/widgets/shop_card.dart';
import '../../../../../../core/widgets/category_card.dart';
import '../../../../../../core/widgets/cart_badge_icon.dart';
import '../../../../../../core/widgets/market_selector.dart';
import '../../../../../../core/widgets/buyer_loading.dart';
import '../../../../../../core/config/route_name.dart';
import '../../../../../../core/router/app_router.dart';

class IngredientScreen extends StatelessWidget {
  const IngredientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IngredientCubit()..loadIngredientData(),
      child: const _IngredientView(),
    );
  }
}

class _IngredientView extends StatefulWidget {
  const _IngredientView();

  @override
  State<_IngredientView> createState() => _IngredientViewState();
}

class _IngredientViewState extends State<_IngredientView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<IngredientCubit>().loadMoreProducts();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9); // Load khi scroll đến 90%
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<IngredientCubit, IngredientState>(
        builder: (context, state) {
          if (state is IngredientLoading) {
            return const BuyerLoading(
              message: 'Đang tải nguyên liệu...',
            );
          }

          if (state is IngredientError) {
            return Center(child: Text(state.message));
          }

          if (state is IngredientLoaded) {
            return _buildIngredientContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
      
    );
  }

  Widget _buildIngredientContent(BuildContext context, IngredientLoaded state) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, state),
          Expanded(
            child: _buildScrollableContent(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IngredientLoaded state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Market Selector
          _buildMarketSelector(context, state),
          const SizedBox(height: 12),
          
          // Search Bar Row
          Row(
            children: [
              // Search Bar
              Expanded(
                child: _buildSearchBar(context, state),
              ),
              const SizedBox(width: 12),
              
              // Cart Icon with Badge
              const CartBadgeIcon(
                iconSize: 26,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, IngredientLoaded state) {
    return GestureDetector(
      onTap: () {
        // Navigate to SearchScreen
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 20,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tìm nguyên liệu...',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSelector(BuildContext context, IngredientLoaded state) {
    return MarketSelector(
      selectedRegion: state.selectedRegion,
      selectedRegionMa: state.selectedRegionMa,
      selectedMarket: state.selectedMarket,
      selectedMarketMa: state.selectedMarketMa,
      onRegionSelected: (maKhuVuc, tenKhuVuc) {
        // Khi chọn khu vực, chưa load nguyên liệu
        // Chờ user chọn chợ
        context.read<IngredientCubit>().selectRegion(maKhuVuc, tenKhuVuc);
      },
      onMarketSelected: (maCho, tenCho) {
        // Khi chọn chợ, load nguyên liệu theo chợ đó
        context.read<IngredientCubit>().loadIngredientsByMarket(maCho, tenCho);
      },
    );
  }

  Widget _buildScrollableContent(BuildContext context, IngredientLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<IngredientCubit>().refreshData(),
      color: const Color(0xFF00B40F),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCategorySection(context, state),
            const SizedBox(height: 24),
            _buildShopsSection(context, state),
            const SizedBox(height: 20),
            _buildProductsSection(context, state),
            
            // Loading indicator khi đang load more
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00B40F),
                  ),
                ),
              ),
            
            // Thông báo khi hết sản phẩm
            if (!state.hasMoreProducts && state.products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Đã hiển thị tất cả sản phẩm',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, IngredientLoaded state) {
    // Merge all categories
    final allCategories = [...state.categories, ...state.additionalCategories];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh mục',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.25,
                ),
              ),
              
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Horizontal Category List
        SizedBox(
          height: 55,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
              return CategoryCard(
                name: category.name,
                imagePath: category.imagePath,
                isSelected: false,
                onTap: () {
                  // Navigate to category ingredients screen
                  if (category.maNhomNguyenLieu != null) {
                    AppRouter.navigateTo(
                      context,
                      RouteName.categoryIngredients,
                      arguments: {
                        'categoryId': category.maNhomNguyenLieu,
                        'categoryName': category.name,
                      },
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopsSection(BuildContext context, IngredientLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gian hàng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.25,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to all shops screen
                  AppRouter.navigateTo(context, RouteName.allShops);
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF008EDB),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Horizontal Shop List
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.shops.length,
            itemBuilder: (context, index) {
              final shop = state.shops[index];
              return ShopCard(
                shopId: shop.id,
                shopName: shop.name,
                shopImage: shop.imagePath,
                rating: shop.rating,
                distance: shop.distance,
                onTap: () {
                  // Navigate to shop detail
                  AppRouter.navigateTo(
                    context,
                    RouteName.shop,
                    arguments: shop.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection(BuildContext context, IngredientLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.products.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 0.7,
          color: Color(0x2E5E5C5C),
        ),
        itemBuilder: (context, index) {
          final product = state.products[index];
          final shopName = index < state.shopNames.length ? state.shopNames[index] : '';
          return _buildProductItem(context, product, shopName);
        },
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product, String shopName) {
    // Hàm navigate đến trang chi tiết
    void navigateToDetail() {
      Navigator.pushNamed(
        context,
        '/ingredient-detail',
        arguments: {
          'maNguyenLieu': product.maNguyenLieu,
          'name': product.name,
          'image': product.imagePath,
          'price': product.price,
          'shopName': shopName,
        },
      );
    }

    return IngredientCard(
      name: product.name,
      price: product.price,
      imagePath: product.imagePath,
      shopName: shopName,
      hasDiscount: product.hasDiscount,
      originalPrice: product.originalPrice,
      onAddToCart: navigateToDetail, // Navigate để chọn gian hàng trước khi thêm
      onBuyNow: () => context.read<IngredientCubit>().buyNow(context, product), // Chuyển thẳng đến thanh toán
      onTap: navigateToDetail,
    );
  }
}
