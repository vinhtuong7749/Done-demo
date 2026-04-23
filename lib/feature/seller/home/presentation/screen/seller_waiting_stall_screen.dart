import 'package:flutter/material.dart';
import '../../../../../core/services/auth/auth_service.dart';
import '../../../../../core/dependency/injection.dart';
import '../../../../../core/config/route_name.dart';

/// Màn hình hiển thị khi người bán đã đăng ký nhưng chưa được
/// quản lý chợ tạo gian hàng. Họ không thể vào app cho đến khi
/// admin tạo gian hàng cho họ.
class SellerWaitingStallScreen extends StatelessWidget {
  const SellerWaitingStallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    // Top bar với logout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white70, size: 18),
                            label: const Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Animated icon
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (ctx, v, child) => Transform.scale(
                              scale: v,
                              child: child,
                            ),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.store_mall_directory_outlined,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Title
                          const Text(
                            'Chờ tạo gian hàng',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Text(
                              'Tài khoản của bạn đã được tạo thành công!\n\nQuản lý chợ sẽ tạo gian hàng cho bạn trong thời gian sớm nhất. Khi có gian hàng, bạn có thể đăng nhập lại để bắt đầu bán hàng.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Steps
                          _buildStep(
                            icon: Icons.check_circle_rounded,
                            color: Colors.greenAccent,
                            title: 'Đã hoàn thành',
                            subtitle: 'Tạo tài khoản người bán',
                          ),
                          const SizedBox(height: 12),
                          _buildStep(
                            icon: Icons.hourglass_top_rounded,
                            color: Colors.amber,
                            title: 'Đang chờ',
                            subtitle: 'Quản lý chợ tạo gian hàng',
                          ),
                          const SizedBox(height: 12),
                          _buildStep(
                            icon: Icons.lock_outline_rounded,
                            color: Colors.white38,
                            title: 'Sắp tới',
                            subtitle: 'Kích hoạt & bắt đầu bán hàng',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Refresh button
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _checkAndReload(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2E7D32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text(
                                'Kiểm tra lại',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nhấn "Kiểm tra lại" sau khi được thông báo\ntừ quản lý chợ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _checkAndReload(BuildContext context) async {
    // Logout và yêu cầu login lại để splash check gian hàng
    await getIt<AuthService>().logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteName.splash,
        (route) => false,
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await getIt<AuthService>().logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteName.login,
        (route) => false,
      );
    }
  }
}

