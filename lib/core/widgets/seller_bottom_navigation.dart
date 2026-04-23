import 'package:flutter/material.dart';

/// Seller Bottom Navigation Widget - Modern Design with order badge
class SellerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final int notificationCount;  // Giữ lại cho Tài khoản (nếu cần)
  final int pendingOrderCount;  // Badge đỏ trên tab Đơn hàng

  const SellerBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.notificationCount = 0,
    this.pendingOrderCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context,
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: 'Trang chủ',
              index: 0,
            ),
            _buildNavItem(context,
              icon: Icons.inventory_2_rounded,
              outlineIcon: Icons.inventory_2_outlined,
              label: 'Sản phẩm',
              index: 1,
            ),
            // Tab Đơn hàng — có badge khi có đơn chờ xác nhận
            _buildNavItemWithBadge(context,
              icon: Icons.receipt_long_rounded,
              outlineIcon: Icons.receipt_long_outlined,
              label: 'Đơn hàng',
              index: 2,
              badgeCount: pendingOrderCount,
              badgeColor: Colors.red,
            ),
            _buildNavItem(context,
              icon: Icons.bar_chart_rounded,
              outlineIcon: Icons.bar_chart_outlined,
              label: 'Doanh số',
              index: 3,
            ),
            _buildNavItemWithBadge(context,
              icon: Icons.person_rounded,
              outlineIcon: Icons.person_outline_rounded,
              label: 'Tài khoản',
              index: 4,
              badgeCount: notificationCount,
              badgeColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    required int index,
  }) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) onTap?.call(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 0, vertical: 4),
                decoration: isSelected
                    ? BoxDecoration(
                        color: const Color(0xFF26CD3A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Icon(
                  isSelected ? icon : outlineIcon,
                  size: 26,
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    BuildContext context, {
    required IconData icon,
    required IconData outlineIcon,
    required String label,
    required int index,
    int badgeCount = 0,
    Color badgeColor = Colors.red,
  }) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) onTap?.call(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 0, vertical: 4),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: const Color(0xFF26CD3A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Icon(
                      isSelected ? icon : outlineIcon,
                      size: 26,
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  // Badge số lượng
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF9CA3AF),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
