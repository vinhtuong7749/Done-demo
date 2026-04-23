import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/ingredient_cubit.dart';
import '../cubit/ingredient_state.dart';

class SellerIngredientScreen extends StatelessWidget {
  const SellerIngredientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerIngredientCubit()..loadIngredients(),
      child: const _SellerIngredientView(),
    );
  }
}

class _SellerIngredientView extends StatelessWidget {
  const _SellerIngredientView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền sáng nhẹ nhàng
      body: BlocBuilder<SellerIngredientCubit, SellerIngredientState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.navigateTo(context, RouteName.sellerAddIngredient),
        backgroundColor: const Color(0xFF00C800),
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text(
          'Thêm mới', 
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  /// Header thiết kế lại hiện đại, nền trắng tinh giản
  Widget _buildHeader(BuildContext context, SellerIngredientState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sản phẩm',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.filteredIngredients.length} SP',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              onChanged: (value) => context.read<SellerIngredientCubit>().updateSearchQuery(value),
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontFamily: 'Inter'),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên sản phẩm...',
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400], fontFamily: 'Inter'),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00C800), size: 24),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Body với danh sách sản phẩm
  Widget _buildBody(BuildContext context, SellerIngredientState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C800)),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<SellerIngredientCubit>().refreshData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C800),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ingredients = state.filteredIngredients;

    if (ingredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn "Thêm mới" để cập nhật sản phẩm',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SellerIngredientCubit>().refreshData(),
      color: const Color(0xFF00C800),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 100), // padding bottom để không bị che bởi FAB
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildIngredientCard(context, ingredients[index]),
          );
        },
      ),
    );
  }

  /// Card sản phẩm với thiết kế mới
  Widget _buildIngredientCard(BuildContext context, SellerIngredient ingredient) {
    final isOutOfStock = ingredient.availableQuantity == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isOutOfStock ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
          width: 1,
        )
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await AppRouter.navigateTo(
              context, 
              RouteName.sellerUpdateIngredient,
              arguments: ingredient,
            );
            if (result == true && context.mounted) {
              context.read<SellerIngredientCubit>().refreshData();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hình ảnh sản phẩm (Bo tròn lớn hơn)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          ingredient.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined, size: 32, color: Colors.grey[350]),
                        ),
                        if (isOutOfStock)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(
                              child: Text(
                                'HẾT',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ingredient.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Giá
                      Row(
                        children: [
                          Text(
                            ingredient.formattedPrice,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF00C800),
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            ingredient.unit,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Kho & ID
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildModernChip(
                            icon: Icons.inventory_2,
                            text: 'Kho: ${ingredient.availableQuantity}',
                            color: isOutOfStock ? Colors.red : const Color(0xFF4FC3F7),
                          ),
                          _buildModernChip(
                            icon: Icons.tag,
                            text: ingredient.id,
                            color: Colors.grey,
                            isOutlined: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút thao tác dọc
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await AppRouter.navigateTo(
                          context,
                          RouteName.sellerUpdateIngredient,
                          arguments: ingredient,
                        );
                        if (result == true && context.mounted) {
                          context.read<SellerIngredientCubit>().refreshData();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                      color: const Color(0xFF00C800),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF00C800).withValues(alpha: 0.1),
                      ),
                      iconSize: 20,
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context, ingredient),
                      icon: const Icon(Icons.delete_rounded),
                      color: Colors.red[400],
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernChip({
    required IconData icon,
    required String text,
    required Color color,
    bool isOutlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
        border: isOutlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, SellerIngredient ingredient) {
    // Lưu cubit reference trước khi mở dialog
    final cubit = context.read<SellerIngredientCubit>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${ingredient.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Hiển thị loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00B40F)),
                ),
              );
              
              // Gọi API xóa
              final success = await cubit.deleteIngredient(ingredient.id);
              
              // Đóng loading dialog
              if (context.mounted) {
                Navigator.pop(context);
              }
              
              // Hiển thị kết quả
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Đã xóa "${ingredient.name}" thành công'
                        : 'Không thể xóa sản phẩm',
                    ),
                    backgroundColor: success ? const Color(0xFF00B40F) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                
                // Clear error nếu có
                if (!success) {
                  cubit.clearError();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
