import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../../core/models/seller_order_model.dart' as model;

class RecentOrdersSection extends StatelessWidget {
  final SellerHomeState state;

  const RecentOrdersSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đơn hàng mới',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            TextButton(
              onPressed: () => AppRouter.navigateTo(context, RouteName.sellerOrder),
              child: const Text('Tất cả', style: TextStyle(color: Color(0xFF26CD3A), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.recentOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Không có đơn hàng mới nào', style: TextStyle(color: Colors.grey))),
          )
        else
          ...state.recentOrders.map((order) => _buildOrderCard(context, order)),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, model.SellerOrderModel order) {
    final cubit = context.read<SellerHomeCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              image: order.chiTietDonHang.isNotEmpty && order.chiTietDonHang[0].hinhAnh != null ? DecorationImage(
                image: NetworkImage(order.chiTietDonHang[0].hinhAnh!),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: order.chiTietDonHang.isEmpty || order.chiTietDonHang[0].hinhAnh == null ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.chiTietDonHang.isNotEmpty ? order.chiTietDonHang[0].tenNguyenLieu : 'Đơn hàng',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '#${order.maDonHang} • ${_formatTime(order.thoiGianGiaoHang)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  cubit.formatCurrency(order.tongTien),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26CD3A),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => AppRouter.navigateTo(context, RouteName.sellerOrder),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Xử lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'N/A';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${time.day}/${time.month}';
  }
}
