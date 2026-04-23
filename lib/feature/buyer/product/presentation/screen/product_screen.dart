import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/widgets/product_list_item.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/widgets/error_state_view.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../../../../buyer/productdetail/presentation/widget/mon_an_ingredient_bottom_sheet.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCubit()..loadProductData(),
      child: const ProductView(),
    );
  }
}

class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Lắng nghe scroll để load more
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Xử lý khi scroll đến cuối danh sách
  void _onScroll() {
    if (_isBottom) {
      context.read<ProductCubit>().loadMoreProducts();
    }
  }

  /// Kiểm tra đã scroll đến cuối chưa
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Load khi còn cách đáy 200px
    return currentScroll >= (maxScroll - 200);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductError && state.requiresLogin) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      builder: (context, state) {
        // Hiển thị loading chung khi đang load dữ liệu ban đầu
        if (state is ProductLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                _buildHeader(context),
                const Expanded(
                  child: BuyerLoading(message: 'Đang tải món ăn...'),
                ),
              ],
            ),
          );
        }

        // Hiển thị lỗi
        if (state is ProductError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: AppErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<ProductCubit>().loadProductData(),
                  ),
                ),
              ],
            ),
          );
        }

        // Hiển thị nội dung khi đã load xong
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ProductCubit>().refreshData(),
                  color: const Color(0xFF00B40F),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildCategoryTitle(),
                            const SizedBox(height: 16),
                            _buildCategoryTabs(context),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      _buildProductList(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final searchQuery = state is ProductLoaded ? state.searchQuery : '';

        return SafeArea(
          child: Container(
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
                // MarketSelector(
                //   selectedRegion: selectedRegion,
                //   selectedRegionMa: selectedRegionMa,
                //   selectedMarket: selectedMarket,
                //   selectedMarketMa: selectedMarketMa,
                //   onRegionSelected: (maKhuVuc, tenKhuVuc) {
                //     context.read<ProductCubit>().selectRegion(maKhuVuc, tenKhuVuc);
                //   },
                //   onMarketSelected: (maCho, tenCho) {
                //     context.read<ProductCubit>().selectMarket(maCho, tenCho);
                //   },
                // ),
                // const SizedBox(height: 12),

                // Search Bar Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(child: _buildSearchBar(context, searchQuery)),
                    const SizedBox(width: 12),

                    // Cart Icon with Badge
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, String searchQuery) {
    return GestureDetector(
      onTap: () {
        AppRouter.navigateTo(context, RouteName.search);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Color(0xFF8E8E93)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tìm kiếm món ăn..',
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

  /// Category tabs (horizontal scrollable)
  Widget _buildCategoryTabs(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded && state.categories.isNotEmpty) {
          return Container(
            height: 44, // Tăng chiều cao để chứa shadow và padding tốt hơn
            margin: const EdgeInsets.only(left: 25),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final isSelected =
                    state.selectedCategory == category.maDanhMucMonAn;

                return GestureDetector(
                  onTap: () {
                    AppRouter.navigateTo(
                      context,
                      RouteName.categoryProducts,
                      arguments: {
                        'categoryId': category.maDanhMucMonAn,
                        'categoryName': category.tenDanhMucMonAn,
                      },
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12, bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00B40F) // Màu xanh lá chủ đạo
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00B40F)
                            : const Color(0xFFE5E7EB), // Viền xám nhạt khi không chọn
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24), // Bo tròn dạng viên thuốc (Pill shape)
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00B40F).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        category.tenDanhMucMonAn,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14, // Tăng size chữ
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: 0.3,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4B5563), // Chữ xám đậm
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Không hiển thị gì nếu chưa có categories (đã có loading chung)
        return const SizedBox(height: 35);
      },
    );
  }

  /// Category title "Danh mục"
  Widget _buildCategoryTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 28),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Danh mục ',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
            color: Color(0xFF000000),
            height: 1.18,
          ),
        ),
      ),
    );
  }

  /// Product list
  Widget _buildProductList(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          final monAnList = state.monAnList;

          if (monAnList.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có món ăn nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Hiển thị loading indicator ở cuối danh sách khi load more
                if (index >= monAnList.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: BuyerLoadingSmall(size: 32)),
                  );
                }

                final monAnWithImage = monAnList[index];
                final monAn = monAnWithImage.monAn;
                final imageUrl = monAnWithImage.imageUrl;

                return ProductListItem(
                  productName: monAn.tenMonAn,
                  imagePath: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('http')
                            ? imageUrl
                            : '${AppConfig.imageBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl')
                      : 'assets/img/mon_an_icon.png',
                  servings: monAnWithImage.servings,
                  difficulty: monAnWithImage.difficulty,
                  cookTime: monAnWithImage.cookTime,
                  onViewDetail: () {
                    showMonAnIngredientBottomSheet(
                      context,
                      monAn.maMonAn,
                    );
                  },
                );
              }, childCount: monAnList.length + (state.isLoadingMore ? 1 : 0)),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
