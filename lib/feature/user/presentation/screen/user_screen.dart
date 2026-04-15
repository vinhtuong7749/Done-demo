import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';
import '../../../../core/dependency/injection.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/config/route_name.dart';
import '../../../../core/widgets/buyer_loading.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit(authService: getIt<AuthService>())..loadUserData(),
      child: const _UserView(), // Bỏ AuthGuard để tránh check 2 lần
    );
  }
}

class _UserView extends StatelessWidget {
  const _UserView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) {
          // Chuyển hướng đến trang login nếu phiên đăng nhập hết hạn
          if (state.requiresLogin) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
            return;
          }
          
          // Hiển thị lỗi nếu có
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Đóng',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const BuyerLoading(
              message: 'Đang tải thông tin người dùng...',
            );
          }

          return Stack(
            children: [
              _buildScrollableContent(context, state),
              _buildHeader(),
            ],
          );
        },
      ),
      
    );
  }

  Widget _buildScrollableContent(BuildContext context, UserState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 77),
          _buildProfileSection(context, state),
          const SizedBox(height: 24),
          _buildMenuSection(context),
          const SizedBox(height: 40),
          _buildLogoutButton(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Cập nhật thông tin cá nhân
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            iconColor: const Color(0xFF00B40F),
            label: 'Cập nhật thông tin cá nhân',
            onTap: () {
              Navigator.pushNamed(context, RouteName.editProfile);
            },
          ),
          const SizedBox(height: 12),
          // Xem danh sách đơn hàng
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF2196F3),
            label: 'Xem danh sách đơn hàng',
            onTap: () {
              Navigator.pushNamed(context, RouteName.orderList);
            },
          ),
          const SizedBox(height: 12),
          // Giỏ hàng
          _buildMenuItem(
            context,
            icon: Icons.shopping_cart_outlined,
            iconColor: const Color(0xFFFF9800),
            label: 'Giỏ hàng của tôi',
            onTap: () {
              Navigator.pushNamed(context, RouteName.cart);
            },
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF9C27B0),
            label: 'Tin nhắn với người bán',
            onTap: () {
              Navigator.pushNamed(context, RouteName.chat);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF202020),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 77,
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Text(
              'Tài khoản',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.29,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Default user avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF00B40F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 32,
                color: Color(0xFF00B40F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chào mừng bạn!',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF5252)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Đăng Xuất',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFFFF5252),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Đóng dialog trước
              Navigator.pop(dialogContext);
              
              // Gọi logout từ cubit
              await context.read<UserCubit>().logout();
              
              // Navigate về màn hình login
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

}
