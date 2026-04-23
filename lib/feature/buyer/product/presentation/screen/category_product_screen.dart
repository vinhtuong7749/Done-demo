import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/widgets/shared_bottom_navigation.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/widgets/product_list_item.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/category_product_cubit.dart';
import '../cubit/category_product_state.dart';
import '../../../../buyer/productdetail/presentation/widget/mon_an_ingredient_bottom_sheet.dart';

/// Screen hiển thị danh sách món ăn theo danh mục
class CategoryProductScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryProductCubit()
        ..loadCategoryProducts(categoryId: categoryId),
      child: CategoryProductView(categoryName: categoryName),
    );
  }
}

class CategoryProductView extends StatefulWidget {
  final String categoryName;

  const CategoryProductView({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryProductView> createState() => _CategoryProductViewState();
}

class _CategoryProductViewState extends State<CategoryProductView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CategoryProductCubit>().loadMoreProducts();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryProductCubit, CategoryProductState>(
      listener: (context, state) {
        if (state is CategoryProductError && state.requiresLogin) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: BlocBuilder<CategoryProductCubit, CategoryProductState>(
            builder: (context, state) {
              String subtitle = '';
              if (state is CategoryProductLoaded) {
                subtitle = '(${state.totalItems} món)';
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              );
            },
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _buildProductList(context),
        ),
        bottomNavigationBar: const SharedBottomNavigation(currentIndex: 1),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return BlocBuilder<CategoryProductCubit, CategoryProductState>(
      builder: (context, state) {
        if (state is CategoryProductLoading) {
          return const BuyerLoading(
              message: 'Đang tải món ăn...',
            );
        }

        if (state is CategoryProductError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          );
        }

        if (state is CategoryProductLoaded) {
          final monAnList = state.monAnList;

          if (monAnList.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có món ăn nào trong danh mục này',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return Container(
            color: const Color(0xFFFFFFFF),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              itemCount: monAnList.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= monAnList.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final monAnWithImage = monAnList[index];
                final monAn = monAnWithImage.monAn;
                final imageUrl = monAnWithImage.imageUrl;

                return ProductListItem(
                  productName: monAn.tenMonAn,
                  imagePath: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('http') ? imageUrl : '${AppConfig.imageBaseUrl}${imageUrl.startsWith('/') ? '' : '/'}$imageUrl')
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
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
