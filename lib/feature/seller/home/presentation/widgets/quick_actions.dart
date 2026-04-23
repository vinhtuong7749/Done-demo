import 'package:flutter/material.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../screen/seller_notification_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chức năng nhanh',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                _buildItem(
                  context, 'Sản phẩm',
                  Icons.inventory_2_rounded,
                  const Color(0xFF2E7D32),
                  const Color(0xFFE8F5E9),
                  () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 1),
                ),
                const SizedBox(width: 16),
                _buildItem(
                  context, 'Đơn hàng',
                  Icons.receipt_long_rounded,
                  const Color(0xFF1565C0),
                  const Color(0xFFE3F2FD),
                  () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildItem(
                  context, 'Doanh thu',
                  Icons.account_balance_wallet_rounded,
                  const Color(0xFF6A1B9A),
                  const Color(0xFFF3E5F5),
                  () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 3),
                ),
                const SizedBox(width: 16),
                _buildItem(
                  context, 'Cài đặt',
                  Icons.settings_rounded,
                  const Color(0xFFE65100),
                  const Color(0xFFFBE9E7),
                  () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 4),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, String label, IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: bgColor, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
