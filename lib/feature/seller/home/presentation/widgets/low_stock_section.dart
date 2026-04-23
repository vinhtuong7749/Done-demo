import 'package:flutter/material.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/home_state.dart';

class LowStockSection extends StatelessWidget {
  final SellerHomeState state;

  const LowStockSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cảnh báo hết hàng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.lowStockProducts.isEmpty ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.lowStockProducts.length} sản phẩm',
                    style: TextStyle(
                      fontSize: 14,
                      color: state.lowStockProducts.isEmpty ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.lowStockProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'Gian hàng đang hoạt động tốt',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tất cả sản phẩm đều còn đủ số lượng.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (var prod in state.lowStockProducts)
                GestureDetector(
                  onTap: () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 1),
                  child: _buildLowStockCard(context, prod),
                ),
          ],
        ),
      ),
    );
  }


  Widget _buildLowStockCard(BuildContext context, dynamic prod) {
    if (prod == null || prod is! Map) return const SizedBox.shrink();
    final imageUrl = prod['hinh_anh']?.toString();
    final name = prod['ten_nguyen_lieu']?.toString() ?? 'Sản phẩm';
    final sku = prod['ma_nguyen_lieu']?.toString() ?? 'N/A';
    final stock = prod['so_luong_ban']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: imageUrl == null ? const Icon(Icons.image_outlined, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: $sku',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Còn $stock',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tồn kho',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
