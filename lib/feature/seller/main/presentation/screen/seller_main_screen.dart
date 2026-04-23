import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/gian_hang_service.dart';
import '../../../../../core/widgets/seller_bottom_navigation.dart';
import '../../../order/presentation/screen/order_screen.dart';
import '../../../ingredient/presentation/screen/ingredient_screen.dart';
import '../../../home/presentation/screen/home_screen.dart';
import '../../../home/presentation/screen/seller_waiting_stall_screen.dart';
import '../../../revenue/presentation/screen/revenue_screen.dart';
import '../../../user/presentation/screen/seller_user_screen.dart';
import '../cubit/seller_main_cubit.dart';

/// Màn hình chính của seller — với stall guard và global new-order polling
class SellerMainScreen extends StatelessWidget {
  final int initialIndex;

  const SellerMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: GianHangService().checkSellerHasStall(),
      builder: (context, snapshot) {
        // Đang check → show loading splash nhỏ
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF2E7D32),
            body: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        // Chưa có gian hàng → màn hình chờ
        final hasStall = snapshot.data ?? true;
        if (!hasStall) {
          return const SellerWaitingStallScreen();
        }

        // Có gian hàng → vào app bình thường
        return BlocProvider(
          create: (context) {
            final cubit = SellerMainCubit(initialIndex: initialIndex);
            cubit.startGlobalPolling();
            return cubit;
          },
          child: const _SellerMainView(),
        );
      },
    );
  }
}

class _SellerMainView extends StatefulWidget {
  const _SellerMainView();

  @override
  State<_SellerMainView> createState() => _SellerMainViewState();
}

class _SellerMainViewState extends State<_SellerMainView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<SellerMainCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellerMainCubit, SellerMainState>(
      // ② Lắng nghe khi có đơn hàng MỚI — từ bất kỳ tab nào
      listenWhen: (prev, curr) => curr.hasNewOrder && !prev.hasNewOrder,
      listener: (context, state) {
        // ③ Hiện overlay alert nổi bật toàn màn hình
        _showNewOrderAlert(context, state.newOrderCount);
      },
      builder: (context, state) {
        return Scaffold(
          body: BlocListener<SellerMainCubit, SellerMainState>(
            listenWhen: (previous, current) =>
                previous.currentIndex != current.currentIndex,
            listener: (context, state) {
              _pageController.animateToPage(
                state.currentIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _KeepAliveWrapper(child: SellerHomeScreen()),       // 0: Trang chủ
                _KeepAliveWrapper(child: SellerIngredientScreen()), // 1: Sản phẩm
                _KeepAliveWrapper(child: SellerOrderScreen()),      // 2: Đơn hàng
                _KeepAliveWrapper(child: SellerRevenueScreen()),    // 3: Doanh số
                _KeepAliveWrapper(child: SellerUserScreen()),       // 4: Tài khoản
              ],
            ),
          ),
          // ④ Badge số đơn chờ hiển thị trên tab "Đơn hàng"
          bottomNavigationBar: SellerBottomNavigation(
            currentIndex: state.currentIndex,
            pendingOrderCount: state.pendingOrderCount,
            onTap: (index) => context.read<SellerMainCubit>().changeTab(index),
          ),
        );
      },
    );
  }

  void _showNewOrderAlert(BuildContext context, int count) {
    final mainCubit = context.read<SellerMainCubit>();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            mainCubit.changeTab(2); // Chuyển sang tab Đơn hàng
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.55),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pulsing icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🛒 Đơn hàng mới! ($count đơn)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nhấn đây để xem và xác nhận',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget wrapper để giữ trạng thái của child widget (keep-alive)
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
