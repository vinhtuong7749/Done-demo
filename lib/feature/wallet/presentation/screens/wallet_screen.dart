import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/dependency/injection.dart';
import '../../services/wallet_service.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../../models/wallet_model.dart';
import '../widgets/withdrawal_dialog.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  final String walletId;
  final String userRole; // 'nguoi_mua', 'nguoi_ban', 'shipper'
  final String? defaultBankAccount;
  final String? defaultBankName;
  final String? defaultAccountName;

  const WalletScreen({
    super.key,
    required this.walletId,
    required this.userRole,
    this.defaultBankAccount,
    this.defaultBankName,
    this.defaultAccountName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletCubit(
        walletService: getIt<WalletService>(),
        walletId: walletId,
      )..loadWallet(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            userRole == 'nguoi_mua' ? 'Quản lý chi tiêu' : 'Ví doanh thu',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color(0xFFE5E7EB),
              height: 1.0,
            ),
          ),
        ),
        body: const _WalletView(),
      ),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    final parentWidget = context.findAncestorWidgetOfExactType<WalletScreen>()!;
    final userRole = parentWidget.userRole;

    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        if (state is WalletWithdrawSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        } else if (state is WalletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is WalletInitial || (state is WalletLoading && context.read<WalletCubit>().state is! WalletLoaded)) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }

        WalletBalanceResponse? walletData;
        String filterType = 'tat_ca';

        if (state is WalletLoaded) {
          walletData = state.walletData;
          filterType = state.filterType;
        } else if (context.read<WalletCubit>().state is WalletLoaded) {
          final loadedState = context.read<WalletCubit>().state as WalletLoaded;
          walletData = loadedState.walletData;
          filterType = loadedState.filterType;
        }

        if (walletData == null) {
          return const Center(child: Text('Không thể tải dữ liệu ví'));
        }

        return RefreshIndicator(
          onRefresh: () => context.read<WalletCubit>().loadWallet(),
          color: const Color(0xFF059669),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildBalanceCard(context, walletData, userRole, parentWidget),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFilterSection(context, filterType, userRole),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: _buildTransactionList(walletData.chiTiet),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    WalletBalanceResponse data,
    String role,
    WalletScreen config,
  ) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isSellerOrShipper = role == 'nguoi_ban' || role == 'shipper';

    if (!isSellerOrShipper) {
      double tongChiTieu = 0;
      for (var item in data.chiTiet) {
        if (item.huong == 'ra') {
          tongChiTieu += item.soTien;
        }
      }

      final heights = [0.2, 0.5, 0.3, 0.8, 0.4, 0.9, 0.6];
      final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

      return Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG CHI TIÊU',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency.format(tongChiTieu > 0 ? tongChiTieu : data.soDuKhaDung),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiêu 7 ngày gần nhất', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 60 * heights[index],
                              decoration: BoxDecoration(
                                color: heights[index] > 0.7 ? Colors.amber : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[index], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background graphic elements
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      role == 'nguoi_mua' ? 'SỐ DƯ VÍ' : 'DOANH THU KHẢ DỤNG',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Icon(
                      role == 'nguoi_mua' ? Icons.account_balance_wallet_rounded : Icons.storefront_rounded,
                      color: Colors.white60,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatCurrency.format(data.soDuKhaDung),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                if (isSellerOrShipper) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Đang chờ duyệt rút: ${formatCurrency.format(data.tienDangChoRut)}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: data.soDuKhaDung > 0 ? () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => WithdrawalDialog(
                            availableBalance: data.soDuKhaDung,
                            defaultBankAccount: config.defaultBankAccount,
                            defaultBankName: config.defaultBankName,
                            defaultAccountName: config.defaultAccountName,
                            onSubmit: (request) {
                              context.read<WalletCubit>().requestWithdrawal(request);
                            },
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF064E3B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                      ),
                      child: const Text('Rút tiền về ngân hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (!isSellerOrShipper) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.safety_check_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Được bảo mật an toàn 100%', 
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, String currentFilter, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role == 'nguoi_mua' ? 'Lịch sử đi chợ' : 'Lịch sử giao dịch',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'Tất cả', 'tat_ca', currentFilter),
                const SizedBox(width: 10),
                _buildFilterChip(context, 'Hôm nay', 'hom_nay', currentFilter),
                const SizedBox(width: 10),
                _buildFilterChip(context, 'Tuần này', 'tuan_nay', currentFilter),
                const SizedBox(width: 10),
                _buildFilterChip(context, 'Tháng này', 'thang_nay', currentFilter),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, String currentValue) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && !isSelected) {
          context.read<WalletCubit>().loadWallet(filterType: value);
        }
      },
      selectedColor: const Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
        ),
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: isSelected ? const Color(0xFF059669).withValues(alpha: 0.4) : null,
    );
  }

  Widget _buildTransactionList(List<WalletDetailItem> items) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildTransactionItem(item);
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildTransactionItem(WalletDetailItem item) {
    final isVao = item.huong == 'vao';
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formattedAmount = '${isVao ? '+' : '-'}${formatCurrency.format(item.soTien)}';
    
    IconData icon;
    Color iconColor;
    String title;
    
    switch (item.loai) {
      case 'don_hang':
        icon = Icons.shopping_bag_rounded;
        iconColor = const Color(0xFF2E7D32);
        title = 'Đơn hàng';
        break;
      case 'phi_gian_hang':
        icon = Icons.storefront_rounded;
        iconColor = const Color(0xFFF57C00);
        title = 'Phí gian hàng';
        break;
      case 'hoan_hang':
      case 'hoan_tien':
      case 'huy_hang':
      case 'tu_choi':
        icon = Icons.assignment_return_rounded;
        iconColor = const Color(0xFF1565C0);
        title = 'Hoàn tiền';
        break;
      case 'phi_ship':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFF2E7D32);
        title = 'Thù lao giao hàng';
        break;
      case 'loi_giao_hang':
        icon = Icons.warning_rounded;
        iconColor = const Color(0xFFC62828);
        title = 'Phí trừ lỗi/Hoàn hàng';
        break;
      default:
        icon = Icons.swap_horiz_rounded;
        iconColor = const Color(0xFF6B7280);
        title = 'Giao dịch khác';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                if (item.orderId != null) ...[
                  Text(
                    'Đơn: ${item.orderId}',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                ],
                if (item.cancelReason != null) ...[
                  Text(
                    item.cancelReason!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  item.ngay != null ? DateFormat('HH:mm  •  dd/MM/yyyy').format(item.ngay!) : '',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formattedAmount,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isVao ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
