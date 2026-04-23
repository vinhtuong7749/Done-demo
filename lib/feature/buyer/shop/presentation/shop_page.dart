import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/buyer_loading.dart';
import '../../../../core/widgets/ingredient_grid_card.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/config/route_name.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/dependency/injection.dart';
import '../../../buyer/home/presentation/cubit/home_state.dart';
import 'shop_cubit.dart';

class ShopPage extends StatefulWidget {
  final String shopId;
  final List<ShopProductPreview>? suggestedProducts;

  const ShopPage({super.key, required this.shopId, this.suggestedProducts});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ShopCubit>().loadShop(
      widget.shopId,
      suggestedProducts: widget.suggestedProducts,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Khi scroll đến 80% cuối trang, tải thêm
      context.read<ShopCubit>().loadMore();
    }
  }

  /// Kiểm tra xem sản phẩm có phải là đề xuất không
  bool _isProductSuggested(String productName) {
    if (widget.suggestedProducts == null || widget.suggestedProducts!.isEmpty) {
      return false;
    }
    final normalizedName = productName.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return widget.suggestedProducts!.any(
      (sp) =>
          sp.productName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ') ==
          normalizedName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) {
            return const BuyerLoading(message: 'Đang tải gian hàng...');
          }

          if (state is ShopFailure) {
            return AppErrorView(
              message: state.errorMessage,
              onRetry: () => context.read<ShopCubit>().loadShop(widget.shopId),
            );
          }

          // Handle both ShopLoaded and ShopLoadingMore states
          if (state is ShopLoaded) {
            return _buildShopPage(context, state);
          }

          if (state is ShopLoadingMore) {
            // Show shop page with current products while loading more
            return _buildShopPage(
              context,
              ShopLoaded(
                shopInfo: state.shopInfo,
                products: state.products,
                selectedTabIndex: state.selectedTabIndex,
                hasMore: true,
                currentPage: 0,
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShopPage(BuildContext context, ShopLoaded state) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            state.shopInfo.shopName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
              onPressed: () => _openChatWithShop(context, state.shopInfo),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),

        // Shop header với banner và avatar
        SliverToBoxAdapter(child: _buildShopHeader(context, state.shopInfo)),

        // Shop info section
        SliverToBoxAdapter(
          child: _buildShopInfoSection(context, state.shopInfo),
        ),

        // Products section title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202020),
                  ),
                ),
                if (widget.suggestedProducts != null &&
                    widget.suggestedProducts!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B40F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00B40F),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.suggestedProducts!.length} đề xuất',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00B40F),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Products grid using IngredientGridCard
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = state.products[index];
              final isSuggested = _isProductSuggested(product.productName);

              return Stack(
                children: [
                  IngredientGridCard(
                    name: product.productName,
                    price: PriceFormatter.formatPrice(product.price),
                    imagePath: product.productImage,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteName.ingredientDetail,
                        arguments: {
                          'maNguyenLieu': product.productId,
                          'maGianHang': product.shopId,
                        },
                      );
                    },
                    onAddToCart: () async {
                      final success = await context.read<ShopCubit>().addToCart(
                        product.productId,
                        1,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Đã thêm ${product.productName} vào giỏ'
                                  : 'Không thể thêm vào giỏ hàng',
                            ),
                            backgroundColor: success
                                ? const Color(0xFF00B40F)
                                : Colors.red,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    onBuyNow: () {
                      // Navigate to payment with buy now
                      Navigator.pushNamed(
                        context,
                        RouteName.payment,
                        arguments: {
                          'isBuyNow': true,
                          'maNguyenLieu': product.productId,
                          'tenNguyenLieu': product.productName,
                          'maGianHang': product.shopId,
                          'hinhAnh': product.productImage,
                          'gia': product.price.toString(),
                          'soLuong': 1,
                        },
                      );
                    },
                  ),
                  // Suggested badge
                  if (isSuggested)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B40F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Đề xuất',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }, childCount: state.products.length),
          ),
        ),

        // Loading indicator khi đang tải thêm
        SliverToBoxAdapter(
          child: BlocBuilder<ShopCubit, ShopState>(
            builder: (context, loadingState) {
              if (loadingState is ShopLoadingMore) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00B40F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đang tải thêm sản phẩm...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Header với banner xanh và avatar + tên shop đè lên
  Widget _buildShopHeader(BuildContext context, ShopInfo shopInfo) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner màu xanh lá gradient
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00D111), Color(0xFF009C0D)],
              ),
            ),
          ),
          
          // Tấm nền trắng bo góc chứa thông tin, đẩy lên ăn nhẹ vào banner
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          // Avatar và thông tin shop
          Positioned(
            left: 20,
            right: 20,
            top: 95,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildShopImage(shopInfo.shopImage),
                  ),
                ),
                const SizedBox(width: 16),
                // Shop name và rating
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopInfo.shopName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB800),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    shopInfo.shopRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB38000),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${shopInfo.reviewCount} đánh giá)',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shop info section với stats và location
  Widget _buildShopInfoSection(BuildContext context, ShopInfo shopInfo) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.inventory_2_rounded,
                  '${shopInfo.productCount}',
                  'Sản phẩm',
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: const Color(0xFFE9ECEF),
                ),
                _buildStatItem(
                  Icons.rate_review_rounded,
                  '${shopInfo.reviewCount}',
                  'Đánh giá',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Location
          if (shopInfo.cho != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF00B40F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopInfo.cho!.tenCho,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${shopInfo.viTri} - ${shopInfo.cho!.diaChi}',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00B40F), size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF212529),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF868E96),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildShopImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: const Icon(Icons.store, size: 40, color: Color(0xFF8E8E93)),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF5F5F5),
          child: const Icon(Icons.store, size: 40, color: Color(0xFF8E8E93)),
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF5F5F5),
        child: const Icon(Icons.store, size: 40, color: Color(0xFF8E8E93)),
      ),
    );
  }

  Future<void> _openChatWithShop(
    BuildContext context,
    ShopInfo shopInfo,
  ) async {
    try {
      final chatService = getIt<ChatService>();
      final conversation = await chatService.createConversation(
        shopInfo.shopId,
      );

      if (!context.mounted) return;

      Navigator.pushNamed(
        context,
        RouteName.chatRoom,
        arguments: {
          'conversationId': conversation.conversationId,
          'title': shopInfo.shopName,
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
