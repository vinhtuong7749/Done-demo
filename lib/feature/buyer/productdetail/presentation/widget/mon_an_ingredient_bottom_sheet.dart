import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/widgets/error_state_view.dart';
import '../../../../../core/widgets/ingredient_grid_card.dart';
import '../cubit/productdetail_cubit.dart';
import '../cubit/productdetail_state.dart';

void showMonAnIngredientBottomSheet(BuildContext context, String maMonAn) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext bottomSheetContext) {
      return BlocProvider(
        create: (_) => ProductDetailCubit()..loadProductDetails(maMonAn),
        child: const _MonAnIngredientBottomSheet(),
      );
    },
  );
}

class _MonAnIngredientBottomSheet extends StatelessWidget {
  const _MonAnIngredientBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: BuyerLoading(message: 'Đang tải thông tin nguyên liệu...'));
          }

          if (state.errorMessage != null) {
            return Center(
              child: AppErrorView(
                message: state.errorMessage!,
                onRetry: () {
                  context.read<ProductDetailCubit>().loadProductDetails(state.maMonAn ?? '');
                },
              ),
            );
          }

          return Column(
            children: [
              // Header
              _buildHeader(context, state),
              
              // Nội dung cuộn
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildRecipeSummary(context, state),
                      _buildIngredientLists(context, state),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Bar
              _buildBottomBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProductDetailState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Nguyên liệu món ${state.productName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSummary(BuildContext context, ProductDetailState state) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Tắt bottom sheet
        Navigator.pushNamed(context, RouteName.monAnInstruction, arguments: state.maMonAn);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: state.productImage.isNotEmpty
                      ? (state.productImage.startsWith('http')
                          ? Image.network(state.productImage, width: 48, height: 48, fit: BoxFit.cover)
                          : Image.asset(state.productImage, width: 48, height: 48, fit: BoxFit.cover))
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, color: Colors.grey, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cách nấu & Sơ chế',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Xem chi tiết hướng dẫn chế biến',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), // Xanh nhạt
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF2F8000), size: 14),
                ),
              ],
            ),
            if (state.doKho != null || state.khoangThoiGian != null || state.calories != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (state.khoangThoiGian != null)
                    _buildQuickInfo(Icons.timer_outlined, '${state.khoangThoiGian} phút'),
                  if (state.doKho != null)
                    _buildQuickInfo(Icons.whatshot_outlined, state.doKho!),
                  if (state.calories != null)
                    _buildQuickInfo(Icons.local_fire_department_outlined, '${state.calories} Cal'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientLists(BuildContext context, ProductDetailState state) {
    if (state.nguyenLieu == null || state.nguyenLieu!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Không có nguyên liệu cho món này.'),
      );
    }

    final nguyenLieuChinh = state.nguyenLieu!.where((item) => !item.isGiaVi).toList();
    final giaVi = state.nguyenLieu!.where((item) => item.isGiaVi).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nguyenLieuChinh.isNotEmpty)
          _buildHorizontalSection(context, 'Lựa chọn loại nguyên liệu chính', nguyenLieuChinh),
        if (giaVi.isNotEmpty)
          _buildHorizontalSection(context, 'Mua thêm gia vị', giaVi),
      ],
    );
  }

  Widget _buildHorizontalSection(BuildContext context, String title, List<NguyenLieuInfo> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final nl = items[index];
              final gianHang = nl.preferredGianHang;
              final isAvailable = nl.hasAvailableShop;

              return Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: IngredientGridCard(
                  name: nl.ten,
                  price: nl.giaDisplay ?? (nl.dinhLuong.isNotEmpty ? nl.dinhLuong : null),
                  imagePath: nl.hinhAnh,
                  shopName: gianHang?.tenGianHang ?? 'Không có gian hàng',
                  isShopOpen: isAvailable,
                  onTap: () {
                    if (nl.maNguyenLieu != null) {
                      Navigator.pushNamed(context, RouteName.ingredientDetail, arguments: {
                        'maNguyenLieu': nl.maNguyenLieu,
                        'ingredientName': nl.ten,
                      });
                    }
                  },
                  onAddToCart: () async {
                    final success = await context.read<ProductDetailCubit>().addToCartIngredient(nl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Đã thêm ${nl.ten} vào giỏ hàng' : 'Không thể thêm ${nl.ten}'),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onBuyNow: () {
                    if (nl.maNguyenLieu != null) {
                      Navigator.pushNamed(context, RouteName.ingredientDetail, arguments: {
                        'maNguyenLieu': nl.maNguyenLieu,
                        'ingredientName': nl.ten,
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductDetailState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () async {
            if (state.nguyenLieu == null || state.nguyenLieu!.isEmpty) return;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const BuyerLoading(message: 'Đang thêm vào giỏ hàng...'),
            );

            try {
              final result = await context.read<ProductDetailCubit>().addAllIngredientsToCart();
              if (context.mounted) Navigator.pop(context); // Close dialog

              if (context.mounted) {
                String message;
                if (result.success > 0 && result.failed == 0) {
                  message = 'Đã thêm tất cả ${result.success} mục vào giỏ hàng';
                } else if (result.success > 0 && result.failed > 0) {
                  final skippedNames = result.errors.map((e) => e.split(':').first).join(', ');
                  message = 'Đã thêm ${result.success} mục. Bỏ qua: $skippedNames (hết hàng/không có shop)';
                } else {
                  message = 'Không thể thêm phần nào (các mục đều đã hết hàng hoặc không có shop).';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: result.success > 0 ? Colors.green : Colors.red,
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
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF26CD3A), // Màu xanh chủ đạo của app (Stitch Primary)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'THÊM VÀO GIỎ',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
