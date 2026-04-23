import 'package:flutter/material.dart';
import '../cubit/home_state.dart';
import '../screen/seller_notification_screen.dart';

class HomeHeader extends StatelessWidget {
  final SellerHomeState state;
  final int notificationCount;

  const HomeHeader({super.key, required this.state, this.notificationCount = 0});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: state.isStoreOpen
                ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                : [const Color(0xFFC62828), const Color(0xFFE53935)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getGreeting()}, ${state.shopName} 👋',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.isStoreOpen ? '🟢 Đang hoạt động' : '🔴 Tạm ngưng',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SellerNotificationScreen()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                    if (notificationCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD600),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            notificationCount > 9 ? '9+' : '$notificationCount',
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào sáng';
    if (hour < 18) return 'Chào chiều';
    return 'Chào tối';
  }
}
