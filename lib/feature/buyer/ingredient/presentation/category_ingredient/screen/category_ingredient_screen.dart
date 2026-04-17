import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/category_ingredient_cubit.dart';
import '../cubit/category_ingredient_state.dart';
import '../../../../../../core/widgets/ingredient_card.dart';
import '../../../../../../core/widgets/buyer_loading.dart';
import '../../../../../../core/widgets/cart_badge_icon.dart';
import '../../../../../../core/widgets/error_state_view.dart';

class CategoryIngredientScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryIngredientScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoryIngredientCubit()
            ..loadIngredientsByCategory(categoryId, categoryName),
      child: const _CategoryIngredientView(),
    );
  }
}

class _CategoryIngredientView extends StatefulWidget {
  const _CategoryIngredientView();

  @override
  State<_CategoryIngredientView> createState() =>
      _CategoryIngredientViewState();
}

class _CategoryIngredientViewState extends State<_CategoryIngredientView> {
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
      context.read<CategoryIngredientCubit>().loadMore();
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
      body: BlocBuilder<CategoryIngredientCubit, CategoryIngredientState>(
        builder: (context, state) {
          if (state is CategoryIngredientLoading) {
            return const BuyerLoading(message: 'Đang tải nguyên liệu...');
          }

          if (state is CategoryIngredientError) {
            return _buildErrorView(context, state.message);
          }

          if (state is CategoryIngredientLoaded) {
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
      title: BlocBuilder<CategoryIngredientCubit, CategoryIngredientState>(
        builder: (context, state) {
          final categoryName = state is CategoryIngredientLoaded
              ? state.categoryName
              : 'Danh mục';
          return Text(
            categoryName,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: const [CartBadgeIcon(iconSize: 24), SizedBox(width: 16)],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<CategoryIngredientCubit>().refresh(),
    );
  }

  Widget _buildContent(BuildContext context, CategoryIngredientLoaded state) {
    if (state.ingredients.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CategoryIngredientCubit>().refresh(),
      color: const Color(0xFF00B40F),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: state.ingredients.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 0.7, color: Color(0x2E5E5C5C)),
        itemBuilder: (context, index) {
          if (index >= state.ingredients.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00B40F),
                ),
              ),
            );
          }

          final ingredient = state.ingredients[index];
          return _buildIngredientItem(context, ingredient);
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có nguyên liệu nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    CategoryIngredientItem ingredient,
  ) {
    void navigateToDetail() {
      Navigator.pushNamed(
        context,
        '/ingredient-detail',
        arguments: {
          'maNguyenLieu': ingredient.maNguyenLieu,
          'name': ingredient.tenNguyenLieu,
          'image': ingredient.hinhAnh ?? '',
          'price': ingredient.price,
          'shopName': ingredient.tenNhomNguyenLieu,
        },
      );
    }

    return IngredientCard(
      name: ingredient.tenNguyenLieu,
      price: ingredient.price,
      imagePath: ingredient.hinhAnh ?? 'assets/img/ingredient_product_1.png',
      shopName: ingredient.tenNhomNguyenLieu,
      hasDiscount: ingredient.hasDiscount,
      originalPrice: ingredient.originalPrice,
      onAddToCart: navigateToDetail,
      onBuyNow: navigateToDetail,
      onTap: navigateToDetail,
    );
  }
}
