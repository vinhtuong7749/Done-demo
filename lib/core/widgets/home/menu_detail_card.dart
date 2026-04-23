import 'package:flutter/material.dart';
import '../../../feature/buyer/home/presentation/cubit/home_state.dart';
import '../../router/app_router.dart';
import '../../config/route_name.dart';
import '../../services/cart_api_service.dart';
import '../../../../feature/buyer/productdetail/presentation/widget/mon_an_ingredient_bottom_sheet.dart';

/// Widget hiển thị món ăn chi tiết sau khi chọn menu
class MenuDetailCard extends StatelessWidget {
  final MonAnDetail monAn;

  const MenuDetailCard({
    super.key,
    required this.monAn,
  });

  @override
  Widget build(BuildContext context) {
    // Lọc tất cả nguyên liệu có gian hàng
    final availableIngredients = monAn.nguyenLieu.where((nl) => nl.gianHang.isNotEmpty).toList();

    // Tính chiều cao cho danh sách nguyên liệu (mỗi item ~50px)
    final ingredientListHeight = (availableIngredients.length * 52.0).clamp(100.0, 350.0);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hình ảnh món ăn
          GestureDetector(
            onTap: () => showMonAnIngredientBottomSheet(
              context,
              monAn.maMonAn,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                monAn.hinhAnh,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Thông tin món ăn
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monAn.tenMonAn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(Icons.access_time, '${monAn.khoangThoiGian}\''),
                    const SizedBox(width: 6),
                    _buildInfoChip(Icons.local_fire_department, '${monAn.calories}cal'),
                  ],
                ),
                const SizedBox(height: 8),
                // Danh sách nguyên liệu
                Text(
                  'Nguyên liệu (${availableIngredients.length}):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          // Danh sách nguyên liệu với chiều cao cố định có thể scroll
          SizedBox(
            height: ingredientListHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: availableIngredients.length,
                itemBuilder: (context, index) {
                  return _buildIngredientItem(context, availableIngredients[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(BuildContext context, NguyenLieuDetail nguyenLieu) {
    final bestShop = nguyenLieu.gianHang.isNotEmpty ? nguyenLieu.gianHang.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Tên nguyên liệu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nguyenLieu.ten,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bestShop != null)
                  Text(
                    '${bestShop.gia}đ/${bestShop.donViBan}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Button thêm vào giỏ
          if (bestShop != null)
            GestureDetector(
              onTap: () async {
                try {
                  await CartApiService().addToCart(
                    maNguyenLieu: nguyenLieu.maNguyenLieu,
                    maGianHang: bestShop.maGianHang,
                    soLuong: 1.0,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm ${nguyenLieu.ten} vào giỏ hàng'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF008EDB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
