import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../../../../../core/widgets/search_result_card.dart';
import '../../../../../core/widgets/error_state_view.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../buyer/productdetail/presentation/widget/mon_an_ingredient_bottom_sheet.dart';

/// Search result screen displaying search results
class SearchResultScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit()..search(searchQuery),
      child: _SearchResultScreenView(searchQuery: searchQuery),
    );
  }
}

class _SearchResultScreenView extends StatelessWidget {
  final String searchQuery;

  const _SearchResultScreenView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          searchQuery,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return _buildLoadingView();
          } else if (state is SearchSuccess) {
            return _buildSuccessView(context, state);
          } else if (state is SearchEmpty) {
            return _buildEmptyView(state.query);
          } else if (state is SearchError) {
            return _buildErrorView(context, state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return const BuyerLoading(message: 'Đang tải...');
  }

  Widget _buildSuccessView(BuildContext context, SearchSuccess state) {
    return ListView(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Tìm thấy ${state.data.totalResults} kết quả',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),

        // Gian hàng
        if (state.data.stalls.isNotEmpty) ...[
          _buildSectionHeader('Gian hàng (${state.data.stalls.length})'),
          ...state.data.stalls.map(
            (stall) => SearchResultCard(
              title: stall.name,
              subtitle: 'Gian hàng',
              imageUrl: stall.image,
              defaultIcon: Icons.store,
              onTap: () {
                AppRouter.navigateTo(
                  context,
                  RouteName.shop,
                  arguments: stall.id,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Món ăn
        if (state.data.dishes.isNotEmpty) ...[
          _buildSectionHeader('Món ăn (${state.data.dishes.length})'),
          ...state.data.dishes.map(
            (dish) => SearchResultCard(
              title: dish.name,
              subtitle: 'Món ăn',
              imageUrl: dish.image,
              defaultIcon: Icons.restaurant,
              onTap: () {
                showMonAnIngredientBottomSheet(
                  context,
                  dish.id,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Nguyên liệu
        if (state.data.ingredients.isNotEmpty) ...[
          _buildSectionHeader('Nguyên liệu (${state.data.ingredients.length})'),
          ...state.data.ingredients.map(
            (ingredient) => SearchResultCard(
              title: ingredient.name,
              subtitle: 'Nguyên liệu',
              imageUrl: ingredient.image,
              defaultIcon: Icons.shopping_basket,
              onTap: () {
                AppRouter.navigateTo(
                  context,
                  RouteName.ingredientDetail,
                  arguments: {
                    'maNguyenLieu': ingredient.id,
                    'name': ingredient.name,
                    'image': ingredient.image ?? '',
                    'price': '',
                    'unit': null,
                    'shopName': null,
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF00B40F),
        ),
      ),
    );
  }

  Widget _buildEmptyView(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả cho "$query"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return AppErrorView(
      message: message,
      onRetry: () {
        context.read<SearchCubit>().search(searchQuery);
      },
    );
  }
}
