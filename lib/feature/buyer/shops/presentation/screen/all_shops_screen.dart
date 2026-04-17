import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/all_shops_cubit.dart';
import '../cubit/all_shops_state.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/widgets/cart_badge_icon.dart';
import '../../../../../core/widgets/error_state_view.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';

class AllShopsScreen extends StatelessWidget {
  const AllShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AllShopsCubit()..loadAllShops(),
      child: const _AllShopsView(),
    );
  }
}

class _AllShopsView extends StatefulWidget {
  const _AllShopsView();

  @override
  State<_AllShopsView> createState() => _AllShopsViewState();
}

class _AllShopsViewState extends State<_AllShopsView> {
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
      context.read<AllShopsCubit>().loadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: BlocBuilder<AllShopsCubit, AllShopsState>(
        builder: (context, state) {
          if (state is AllShopsLoading) {
            return const BuyerLoading(message: 'Đang tải gian hàng...');
          }

          if (state is AllShopsError) {
            return _buildErrorView(context, state.message);
          }

          if (state is AllShopsLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Tất cả gian hàng',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: const [CartBadgeIcon(iconSize: 24), SizedBox(width: 16)],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<AllShopsCubit>().refresh(),
    );
  }

  Widget _buildContent(BuildContext context, AllShopsLoaded state) {
    if (state.shops.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AllShopsCubit>().refresh(),
      color: const Color(0xFF00B40F),
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.shops.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= state.shops.length) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00B40F),
              ),
            );
          }

          final shop = state.shops[index];
          return _buildShopCard(context, shop);
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không có gian hàng nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopItem shop) {
    final isNetworkImage =
        shop.hinhAnh != null &&
        (shop.hinhAnh!.startsWith('http://') ||
            shop.hinhAnh!.startsWith('https://'));

    return GestureDetector(
      onTap: () {
        AppRouter.navigateTo(
          context,
          RouteName.shop,
          arguments: shop.maGianHang,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: shop.hinhAnh != null && isNetworkImage
                    ? Image.network(
                        shop.hinhAnh!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),

            // Shop Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name
                    Text(
                      shop.tenGianHang,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shop.viTri,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: Color(0xFF8E8E93),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Rating
                    if (shop.danhGiaTb > 0)
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              shop.danhGiaTb.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Icon(Icons.store, size: 40, color: Color(0xFF00B40F)),
      ),
    );
  }
}
