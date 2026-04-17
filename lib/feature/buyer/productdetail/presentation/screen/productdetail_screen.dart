import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/productdetail_cubit.dart';
import '../cubit/productdetail_state.dart';
import '../../../../../core/widgets/ingredient_list_item.dart';
import '../../../../../core/widgets/ingredient_grid_card.dart';
import '../../../../../core/widgets/cart_icon_with_badge.dart';
import '../../../../../core/widgets/error_state_view.dart';
import '../../../../../core/config/route_name.dart';

class ProductDetailScreen extends StatelessWidget {
  final String? maMonAn; // Mã món ăn từ ProductScreen

  const ProductDetailScreen({super.key, this.maMonAn});

  @override
  Widget build(BuildContext context) {
    // Lấy maMonAn từ route arguments nếu không truyền trực tiếp
    final String finalMaMonAn =
        maMonAn ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        '';

    return BlocProvider(
      create: (context) =>
          ProductDetailCubit()..loadProductDetails(finalMaMonAn),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const BuyerLoading(message: 'Đang tải chi tiết món ăn...');
          }

          if (state.errorMessage != null) {
            return AppErrorView(
              message: state.errorMessage!,
              onRetry: () {
                context.read<ProductDetailCubit>().loadProductDetails(
                  state.maMonAn ?? '',
                );
              },
            );
          }

          return Stack(
            children: [
              _buildScrollableContent(context, state),
              _buildHeader(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScrollableContent(
    BuildContext context,
    ProductDetailState state,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 86),
          _buildProductImage(state),
          _buildProductTitle(state),
          const SizedBox(height: 10),
          const Divider(height: 2, thickness: 2, color: Color(0xFFD9D9D9)),
          const SizedBox(height: 10),
          _buildText(state),
          _buildProductInfo(context, state),
          _buildExpandButton(),
          _buildRelatedProductsTitle(context),
          _buildRelatedProducts(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProductDetailState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 91, // Giống header iOS
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 22,
                    color: Colors.black,
                  ),
                ),

                // Icon giỏ hàng bên phải
                CartIconWithBadge(
                  itemCount: state.cartItemCount,
                  onTap: () {
                    Navigator.pushNamed(context, RouteName.cart);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductDetailState state) {
    // Kiểm tra xem productImage có phải URL không
    final bool isUrl =
        state.productImage.startsWith('http://') ||
        state.productImage.startsWith('https://');

    if (isUrl) {
      // Nếu là URL, dùng Image.network()
      return Image.network(
        state.productImage,
        width: double.infinity,
        height: 308,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 308,
            color: Colors.grey[200],
            child: const Center(child: BuyerLoading()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 308,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      // Nếu là asset, dùng Image.asset()
      return Image.asset(
        state.productImage.isNotEmpty
            ? state.productImage
            : 'assets/img/mon_an_icon.png',
        width: double.infinity,
        height: 308,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 308,
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  Widget _buildProductTitle(ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, top: 12),
      child: Text(
        state.productName,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildText(ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        "Định lượng",
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.21,
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin cơ bản (luôn hiển thị)
          if (state.doKho != null) _buildInfoRow('Độ khó', state.doKho!),
          if (state.khoangThoiGian != null)
            _buildInfoRow('Thời gian nấu', '${state.khoangThoiGian} phút'),
          if (state.khauPhanTieuChuan != null)
            _buildKhauPhanRow(context, state),
          if (state.calories != null)
            _buildInfoRow('Calories', '${state.calories} Cal'),

          const SizedBox(height: 12),

          // Nguyên liệu (luôn hiển thị)
          if (state.nguyenLieu != null && state.nguyenLieu!.isNotEmpty) ...[
            const Text(
              'Nguyên liệu:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.21,
              ),
            ),
            const SizedBox(height: 8),
            ...state.nguyenLieu!.map((nl) {
              return IngredientListItem(
                tenNguyenLieu: nl.ten,
                dinhLuong: nl.dinhLuong,
                donViGoc: nl.donVi,
              );
            }),
            const SizedBox(height: 12),
          ],

          // Phần chi tiết (chỉ hiển thị khi mở rộng)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(state),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ProductDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sơ chế
        if (state.soChe != null && state.soChe!.isNotEmpty) ...[
          const Text(
            'Sơ chế:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.soChe!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Cách thực hiện
        if (state.cachThucHien != null && state.cachThucHien!.isNotEmpty) ...[
          const Text(
            'Cách thực hiện:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.cachThucHien!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Cách dùng
        if (state.cachDung != null && state.cachDung!.isNotEmpty) ...[
          const Text(
            'Cách dùng:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.cachDung!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Danh mục
        if (state.danhMuc != null && state.danhMuc!.isNotEmpty) ...[
          const Text(
            'Danh mục:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.danhMuc!.map((dm) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  dm.ten,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2F8000),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhauPhanRow(BuildContext context, ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Khẩu phần:',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
          ),
          Row(
            children: [
              // Nút giảm
              GestureDetector(
                onTap: () {
                  context.read<ProductDetailCubit>().decreaseKhauPhan();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: state.currentKhauPhan > 1
                        ? const Color(0xFF2F8000)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: state.currentKhauPhan > 1
                        ? Colors.white
                        : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Hiển thị số khẩu phần
              SizedBox(
                width: 40,
                child: Text(
                  '${state.currentKhauPhan}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút tăng
              GestureDetector(
                onTap: () {
                  context.read<ProductDetailCubit>().increaseKhauPhan();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F8000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'người',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 155, vertical: 10),
        child: Row(
          children: [
            Text(
              _isExpanded ? 'Thu gọn' : 'Xem thêm',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductsTitle(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Text(
        'Nguyên liệu cần mua',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.21,
          color: Color(0xFF020202),
        ),
      ),
    );
  }

  Future<void> _addAllToCart(
    BuildContext context,
    List<NguyenLieuInfo> items,
    String sectionLabel,
  ) async {
    if (items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          BuyerLoading(message: 'Đang thêm $sectionLabel vào giỏ hàng...'),
    );

    try {
      final result = await context
          .read<ProductDetailCubit>()
          .addAllIngredientsToCart(items: items);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        final label = sectionLabel.toLowerCase();
        String message;
        if (result.success > 0 && result.failed == 0) {
          message = 'Đã thêm ${result.success} $label vào giỏ hàng';
        } else if (result.success > 0 && result.failed > 0) {
          message =
              'Đã thêm ${result.success} $label, ${result.failed} mục thất bại';
        } else {
          message = 'Không thể thêm $label vào giỏ hàng';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.success > 0 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildRelatedProducts(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state.nguyenLieu == null || state.nguyenLieu!.isEmpty) {
          return const SizedBox.shrink();
        }

        final nguyenLieuCanMua = state.nguyenLieu!
            .where((item) => !item.isGiaVi)
            .toList();
        final giaViCanMua = state.nguyenLieu!
            .where((item) => item.isGiaVi)
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (nguyenLieuCanMua.isNotEmpty)
                _buildIngredientSection(
                  context,
                  title: 'Nguyên liệu',
                  items: nguyenLieuCanMua,
                ),
              if (giaViCanMua.isNotEmpty)
                _buildIngredientSection(
                  context,
                  title: 'Gia vị cần mua',
                  items: giaViCanMua,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIngredientSection(
    BuildContext context, {
    required String title,
    required List<NguyenLieuInfo> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            GestureDetector(
              onTap: () => _addAllToCart(context, items, title),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F8000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_shopping_cart,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Thêm tất cả',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final nl = items[index];
            final gianHang = nl.preferredGianHang;
            final isAvailable = nl.hasAvailableShop;

            return IngredientGridCard(
              name: nl.ten,
              price:
                  nl.giaDisplay ??
                  (nl.dinhLuong.isNotEmpty ? nl.dinhLuong : null),
              imagePath: nl.hinhAnh,
              shopName: gianHang?.tenGianHang ?? 'Không có gian hàng hoạt động',
              isShopOpen: isAvailable,
              onTap: () {
                if (nl.maNguyenLieu != null) {
                  Navigator.pushNamed(
                    context,
                    '/ingredient-detail',
                    arguments: {
                      'maNguyenLieu': nl.maNguyenLieu,
                      'ingredientName': nl.ten,
                    },
                  );
                }
              },
              onAddToCart: () async {
                final success = await context
                    .read<ProductDetailCubit>()
                    .addToCartIngredient(nl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Đã thêm ${nl.ten} vào giỏ hàng'
                            : 'Không thể thêm ${nl.ten} vào giỏ hàng',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              onBuyNow: () {
                if (nl.maNguyenLieu != null) {
                  Navigator.pushNamed(
                    context,
                    '/ingredient-detail',
                    arguments: {
                      'maNguyenLieu': nl.maNguyenLieu,
                      'ingredientName': nl.ten,
                    },
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildReviewSection(ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá từ khách hàng',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.21,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Rating score
              Column(
                children: [
                  Text(
                    '${state.rating}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 0.64,
                      color: Color(0xFF008EDB),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/img/productdetail_star_icon-239c62.png',
                    width: 21,
                    height: 19,
                  ),
                ],
              ),
              const SizedBox(width: 22),
              // Center: Star ratings
              Expanded(
                child: Column(
                  children: state.reviews.map((review) {
                    return _buildReviewRow(review);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Image.asset(
            'assets/img/productdetail_star_icon-239c62.png',
            width: 11,
            height: 10,
          ),
          const SizedBox(width: 5),
          Text(
            '${review.stars}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.33,
              color: Color(0xFF0C0D0D),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: review.percentage,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCC866),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${(review.percentage * 100).toInt()}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w400,
                height: 1.78,
                color: Color(0xFF0C0D0D),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              '${review.count} đánh giá',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                color: Color(0xFF0C0D0D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
