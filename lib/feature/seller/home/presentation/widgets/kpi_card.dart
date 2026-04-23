import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class KPIOverviewCard extends StatelessWidget {
  final SellerHomeState state;

  const KPIOverviewCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellerHomeCubit>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng doanh thu (VND)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cubit.formatCurrency(state.dailyOverview.revenue),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: state.isStoreOpen ? const Color(0xFF1B5E20) : Colors.red[900],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: !state.isStoreOpen 
                      ? Colors.red[50]
                      : state.revenueChangePercentage >= 0 
                          ? const Color(0xFFE8F5E9) 
                          : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.revenueChangePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward, 
                      size: 18, 
                      color: !state.isStoreOpen 
                          ? Colors.red[400]
                          : state.revenueChangePercentage >= 0 ? const Color(0xFF26CD3A) : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.revenueChangePercentage >= 0 ? '+' : ''}${state.revenueChangePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !state.isStoreOpen 
                            ? Colors.red[400]
                            : state.revenueChangePercentage >= 0 ? const Color(0xFF26CD3A) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWeeklyRevenueChart(state),
        ],
      ),
    );
  }

  Widget _buildWeeklyRevenueChart(SellerHomeState state) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maxValue = state.weeklyRevenue.values.fold<double>(0, (max, val) => val > max ? val : max);
    
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final value = state.weeklyRevenue[day] ?? 0;
          final heightPercent = maxValue > 0 ? value / maxValue : 0.1;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 32,
                height: (heightPercent * 80).clamp(5.0, 80.0),
                decoration: BoxDecoration(
                  color: state.isStoreOpen 
                      ? const Color(0xFF26CD3A).withOpacity(day == _getCurrentDayLabel() ? 1.0 : 0.6)
                      : Colors.red[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  color: state.isStoreOpen ? Colors.grey[800] : Colors.red[400],
                  fontWeight: state.isStoreOpen && day == _getCurrentDayLabel() ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getCurrentDayLabel() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      case DateTime.sunday: return 'CN';
      default: return '';
    }
  }
}
