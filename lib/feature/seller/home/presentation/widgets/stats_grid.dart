import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_state.dart';
import '../../../main/presentation/cubit/seller_main_cubit.dart';

class StatsGrid extends StatelessWidget {
  final SellerHomeState state;

  const StatsGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Đơn hàng hôm nay',
            state.dailyOverview.orderCount.toString(),
            Icons.shopping_bag_outlined,
            () => context.read<SellerMainCubit>().changeTab(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Sản phẩm đang bán',
            state.productInfo.activeProducts.toString(),
            Icons.inventory_2_outlined,
            () => context.read<SellerMainCubit>().changeTab(1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF26CD3A), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
