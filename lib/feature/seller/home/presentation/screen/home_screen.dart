import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_header.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_orders_section.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerHomeCubit()..initializeHome(),
      child: const _SellerHomeView(),
    );
  }
}

class _SellerHomeView extends StatelessWidget {
  const _SellerHomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerHomeCubit, SellerHomeState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF26CD3A),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đang tải dữ liệu...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.errorMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Color(0xFF374151), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<SellerHomeCubit>().refreshData(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26CD3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            onRefresh: () => context.read<SellerHomeCubit>().refreshData(),
            color: const Color(0xFF26CD3A),
            child: CustomScrollView(
              slivers: [
                // Header with gradient
                HomeHeader(state: state),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store toggle row (compact)
                        Row(
                          children: [
                            Icon(
                              state.isStoreOpen ? Icons.store_rounded : Icons.store_outlined,
                              color: state.isStoreOpen ? const Color(0xFF2E7D32) : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.isStoreOpen ? 'Gian hàng đang mở' : 'Gian hàng đang đóng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: state.isStoreOpen ? const Color(0xFF2E7D32) : Colors.red[700],
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: state.isStoreOpen,
                                onChanged: (_) => context.read<SellerHomeCubit>().toggleStoreStatus(),
                                activeColor: const Color(0xFF2E7D32),
                                activeTrackColor: const Color(0xFFE8F5E9),
                                inactiveThumbColor: Colors.red,
                                inactiveTrackColor: const Color(0xFFFFEBEE),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        KPIOverviewCard(state: state),
                        const SizedBox(height: 16),
                        StatsGrid(state: state),
                        const SizedBox(height: 20),
                        const QuickActions(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                LowStockSection(state: state),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RecentOrdersSection(state: state),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}
