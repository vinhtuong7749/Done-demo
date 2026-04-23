import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cart_cubit.dart';

import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/buyer_loading.dart';

/// Màn hình giỏ hàng - Code lại với design đẹp hơn
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static const String routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartCubit()..loadCart(),
      child: const CartView(),
    );
  }
}

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartItemRemoved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF26CD3A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else if (state is CartCheckoutSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF26CD3A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else if (state is CartFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F6),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: BlocBuilder<CartCubit, CartState>(
                      builder: (context, state) {
                        if (state is CartLoading) {
                          return const BuyerLoading(
                            message: 'Đang tải giỏ hàng...',
                          );
                        }

                        if (state is CartLoaded) {
                          if (state.items.isEmpty) {
                            return _buildEmptyCart(context);
                          }
                          return _buildCartList(context, state);
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  _buildBottomSection(context),
                ],
              ),
              BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  if (state is CartUpdating) {
                    return const Positioned.fill(
                      child: BuyerLoading(message: 'Đang cập nhật...'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header đẹp hơn với Material Icons
  Widget _buildHeader(BuildContext context) {
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
          // Title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              const Text(
                'Giỏ hàng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 24),
            ],
          ),
          
          // Order ID row has been removed.
          
          const SizedBox(height: 12),
          
          // Address row
          
        ],
      ),
    );
  }

  /// Empty cart với UI đẹp hơn
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Color(0xFF26CD3A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20), // Trầm Forest Green
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng\nđể bắt đầu mua sắm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26CD3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tiếp tục mua sắm',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Danh sách cart items
  Widget _buildCartList(BuildContext context, CartLoaded state) {
    final itemsByShop = <String, List<CartItem>>{};
    for (final item in state.items) {
      if (!itemsByShop.containsKey(item.shopName)) {
        itemsByShop[item.shopName] = [];
      }
      itemsByShop[item.shopName]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // _buildSelectAllSection(context, state),
        const SizedBox(height: 16),
        ...itemsByShop.entries.map((entry) {
          return Column(
            children: [
              _buildShopSection(context, entry.key, entry.value, state),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  /// Section chọn tất cả
  // ignore: unused_element
  Widget _buildSelectAllSection(BuildContext context, CartLoaded state) {
    final cubit = context.read<CartCubit>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => cubit.toggleSelectAll(),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cubit.isAllSelected 
                      ? const Color(0xFF00B40F) 
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
                color: cubit.isAllSelected 
                    ? const Color(0xFF00B40F) 
                    : Colors.white,
              ),
              child: cubit.isAllSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Chọn tất cả',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }

  /// Section của một shop
  Widget _buildShopSection(
    BuildContext context,
    String shopName,
    List<CartItem> items,
    CartLoaded state,
  ) {
    final cubit = context.read<CartCubit>();
    
    // Check if all items in this shop are selected
    final allShopItemsSelected = items.every((item) => item.isSelected);
    final someShopItemsSelected = items.any((item) => item.isSelected);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop header với checkbox
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Checkbox chọn tất cả sản phẩm của shop
                GestureDetector(
                  onTap: () {
                    // Nếu tất cả đã chọn → bỏ chọn tất cả
                    // Nếu chưa chọn hoặc chọn một phần → chọn tất cả
                    final shouldSelect = !allShopItemsSelected;
                    
                    for (final item in items) {
                      // Chỉ toggle nếu trạng thái khác với trạng thái mong muốn
                      if (item.isSelected != shouldSelect) {
                        cubit.toggleItemSelection(item.id);
                      }
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: allShopItemsSelected 
                            ? const Color(0xFF26CD3A) 
                            : someShopItemsSelected
                                ? const Color(0xFF26CD3A).withValues(alpha: 0.5)
                                : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      color: allShopItemsSelected 
                          ? const Color(0xFF26CD3A) 
                          : Colors.white,
                    ),
                    child: allShopItemsSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : someShopItemsSelected
                            ? Container(
                                margin: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF26CD3A),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.store_mall_directory_outlined,
                  size: 20,
                  color: Color(0xFF1B5E20), // Deep Forest Green for icon
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shopName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1B5E20), // Deep Forest Green for text
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
          
          // Products
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildCartItem(context, item, state),
                if (index < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Cart item widget
  Widget _buildCartItem(BuildContext context, CartItem item, CartLoaded state) {
    final cubit = context.read<CartCubit>();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => cubit.toggleItemSelection(item.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isSelected 
                      ? const Color(0xFF26CD3A) 
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
                color: item.isSelected 
                    ? const Color(0xFF26CD3A) 
                    : Colors.white,
              ),
              child: item.isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildProductImage(item.productImage),
          ),
          const SizedBox(width: 16),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  PriceFormatter.formatPrice(item.price),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFFE53935), // Alert Red for price pop
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     _buildQuantityControl(context, cubit, item),
                     // Delete button
                    GestureDetector(
                      onTap: () => cubit.removeItem(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(BuildContext context, CartCubit cubit, CartItem item) {
    final isDecrementDisabled = item.quantity <= 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyButton(
            icon: Icons.remove,
            enabled: !isDecrementDisabled,
            onTap: () {
              if (!isDecrementDisabled) {
                cubit.updateQuantity(item.id, item.quantity - 1);
              }
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          _buildQtyButton(
            icon: Icons.add,
            enabled: true,
            onTap: () => cubit.updateQuantity(item.id, item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF00B40F).withValues(alpha: 0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? const Color(0xFF00B40F) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF00B40F) : Colors.grey[400],
        ),
      ),
    );
  }

  /// Bottom section với tổng tiền
  // Widget _buildBottomSection(BuildContext context) {
  //   return BlocBuilder<CartCubit, CartState>(
  //     builder: (context, state) {
  //       if (state is! CartLoaded) {
  //         return const SizedBox.shrink();
  //       }

  //       final cubit = context.read<CartCubit>();
  //       final isCheckingOut = state is CartCheckoutInProgress;
  //       final selectedCount = state.items.where((item) => item.isSelected).length;

  //       return Container(
  //         decoration: BoxDecoration(
  //           color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.5),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withValues(alpha: 0.1),
  //               blurRadius: 8,
  //               offset: const Offset(0, -2),
  //             ),
  //           ],
  //         ),
  //         padding: const EdgeInsets.all(16),
  //         child: SafeArea(
  //           top: false,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Total row
  //               Row(
  //                 children: [
  //                   GestureDetector(
  //                     onTap: () => cubit.toggleSelectAll(),
  //                     child: Container(
  //                       width: 24,
  //                       height: 24,
  //                       decoration: BoxDecoration(
  //                         shape: BoxShape.circle,
  //                         border: Border.all(
  //                           color: cubit.isAllSelected 
  //                               ? const Color(0xFF00B40F) 
  //                               : const Color(0xFFE0E0E0),
  //                           width: 2,
  //                         ),
  //                         color: cubit.isAllSelected 
  //                             ? const Color(0xFF00B40F) 
  //                             : Colors.white,
  //                       ),
  //                       child: cubit.isAllSelected
  //                           ? const Icon(
  //                               Icons.check,
  //                               size: 16,
  //                               color: Colors.white,
  //                             )
  //                           : null,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Tất cả ($selectedCount)',
  //                     style: const TextStyle(
  //                       fontFamily: 'Roboto',
  //                       fontSize: 14,
  //                       color: Color(0xFF8E8E93),
  //                     ),
  //                   ),
  //                   const Spacer(),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.end,
  //                     children: [
  //                       const Text(
  //                         'Tổng cộng',
  //                         style: TextStyle(
  //                           fontFamily: 'Roboto',
  //                           fontSize: 13,
  //                           color: Color(0xFF8E8E93),
  //                         ),
  //                       ),
  //                       Text(
  //                         PriceFormatter.formatPrice(state.totalAmount),
  //                         style: const TextStyle(
  //                           fontFamily: 'Roboto',
  //                           fontWeight: FontWeight.w700,
  //                           fontSize: 20,
  //                           color: Color(0xFFFF3B30),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),
                
  //               // Checkout button
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 50,
  //                 child: ElevatedButton(
  //                   onPressed: isCheckingOut || selectedCount == 0 
  //                       ? null 
  //                       : () {
  //                           // Get selected items
  //                           final selectedItems = state.items
  //                               .where((item) => item.isSelected)
  //                               .toList();
                            
  //                           // Navigate to payment page with selected items
  //                           Navigator.pushNamed(
  //                             context,
  //                             '/payment',
  //                             arguments: {
  //                               'isFromCart': true,
  //                               'orderCode': state.orderCode, // Mã đơn hàng từ API cart
  //                               'selectedItems': selectedItems.map((item) => {
  //                                 'maNguyenLieu': item.productId,
  //                                 'tenNguyenLieu': item.productName,
  //                                 'maGianHang': item.shopId,
  //                                 'tenGianHang': item.shopName,
  //                                 'hinhAnh': item.productImage,
  //                                 'gia': item.price.toString(),
  //                                 'soLuong': item.quantity,
  //                               }).toList(),
  //                               'totalAmount': state.totalAmount,
  //                             },
  //                           );
  //                         },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF00B40F),
  //                     foregroundColor: Colors.white,
  //                     disabledBackgroundColor: Colors.grey[300],
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     elevation: 0,
  //                   ),
  //                   child: isCheckingOut
  //                       ? const SizedBox(
  //                           width: 24,
  //                           height: 24,
  //                           child: CircularProgressIndicator(
  //                             color: Colors.white,
  //                             strokeWidth: 2,
  //                           ),
  //                         )
  //                       : Text(
  //                           'Thanh toán ($selectedCount)',
  //                           style: const TextStyle(
  //                             fontFamily: 'Roboto',
  //                             fontWeight: FontWeight.w700,
  //                             fontSize: 16,
  //                           ),
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  /// Build product image - support both URL and asset
  Widget _buildProductImage(String imagePath) {
    final isNetworkImage = imagePath.startsWith('http://') || 
                          imagePath.startsWith('https://');
    
    final placeholderWidget = Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 32, color: Colors.grey),
    );

    if (imagePath.isEmpty) {
      return placeholderWidget;
    }

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: const Color(0xFF00B40F),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => placeholderWidget,
      );
    } else {
      return Image.asset(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholderWidget,
      );
    }
  }
}

  /// Bottom section với bố cục mới
  Widget _buildBottomSection(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is! CartLoaded) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<CartCubit>();
        final selectedCount = state.items.where((item) => item.isSelected).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Checkbox "Tất cả"
                GestureDetector(
                  onTap: () => cubit.toggleSelectAll(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cubit.isAllSelected
                                ? const Color(0xFF26CD3A)
                                : const Color(0xFFE0E0E0),
                            width: 2,
                          ),
                          color: cubit.isAllSelected
                              ? const Color(0xFF26CD3A)
                              : Colors.white,
                        ),
                        child: cubit.isAllSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tất cả',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Phần Tổng tiền và Vận chuyển
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tổng cộng
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tổng cộng: ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              PriceFormatter.formatPrice(state.totalAmount),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE53935), // Red alert price
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Miễn phí vận chuyển
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 14,
                            color: Color(0xFF26CD3A),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Miễn phí vận chuyển',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Color(0xFF26CD3A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Nút Mua hàng
                ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          // Lấy danh sách items đã chọn
                          final selectedItems = state.items
                              .where((item) => item.isSelected)
                              .toList();
                          
                          // Navigate to payment page với thông tin từ cart (không gọi API checkout)
                          // Mã đơn hàng sẽ được tạo khi user bấm thanh toán ở trang Payment
                          Navigator.pushNamed(
                            context,
                            '/payment',
                            arguments: {
                              'isFromCart': true,
                              'selectedItems': selectedItems.map((item) {
                                // Lấy shopId - nếu null thì extract từ id (format: maNguyenLieu_maGianHang)
                                String shopId = item.shopId ?? '';
                                if (shopId.isEmpty && item.id.contains('_')) {
                                  final parts = item.id.split('_');
                                  if (parts.length > 1) {
                                    shopId = parts.sublist(1).join('_');
                                  }
                                }
                                return {
                                  'maNguyenLieu': item.productId,
                                  'tenNguyenLieu': item.productName,
                                  'maGianHang': shopId,
                                  'tenGianHang': item.shopName,
                                  'hinhAnh': item.productImage,
                                  'gia': item.price.toString(),
                                  'soLuong': item.quantity,
                                };
                              }).toList(),
                              'totalAmount': state.totalAmount,
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26CD3A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mua hàng ($selectedCount)',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
