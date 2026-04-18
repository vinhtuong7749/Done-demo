import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/route_name.dart';

/// Shared Bottom Navigation Widget
/// Dùng chung cho tất cả các màn hình trong app
class SharedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              context,
              icon: 'assets/img/add_home.svg',
              label: 'Trang chủ',
              index: 0,
              currentIndex: currentIndex,
              route: RouteName.home,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: 'assets/img/mon_an_icon.png',
              label: 'Món ăn',
              index: 1,
              currentIndex: currentIndex,
              route: RouteName.productList,
              isImage: true,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: '',
              iconData: Icons.restaurant_menu_rounded,
              label: 'Thực đơn',
              index: 2,
              currentIndex: currentIndex,
              route: RouteName.menu,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: 'assets/img/ingredient.png',
              label: 'Ng.lệu',
              index: 3,
              currentIndex: currentIndex,
              route: RouteName.ingredient,
              isImage: true,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: 'assets/img/account_circle.svg',
              label: 'Tài khoản',
              index: 4,
              currentIndex: currentIndex,
              route: RouteName.user,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Item
  Widget _buildNavItem(
    BuildContext context, {
    required String icon,
    required String label,
    required int index,
    required int currentIndex,
    String? route,
    bool isImage = false,
    bool isCenter = false,
    IconData? iconData,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () {
        if (isSelected || isCenter) return;
        onTap?.call(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                width: 46,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(icon),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else ...[
              if (iconData != null)
                Icon(
                  iconData,
                  size: 24,
                  color: isSelected
                      ? const Color(0xFF00B40F)
                      : const Color(0xFF000000),
                )
              else if (isImage)
                Image.asset(
                  icon,
                  width: 28,
                  height: 28,
                  color: isSelected ? const Color(0xFF00B40F) : null,
                )
              else
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF00B40F)
                        : const Color(0xFF000000),
                    BlendMode.srcIn,
                  ),
                ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 10,
                    height: 1.2,
                    color: isSelected
                        ? const Color(0xFF00B40F)
                        : const Color(0xFF000000),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
