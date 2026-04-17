import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/config/route_name.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';

class SellerOrderScreen extends StatelessWidget {
  const SellerOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerOrderCubit()..loadOrders(),
      child: const SellerOrderView(),
    );
  }
}

class SellerOrderView extends StatefulWidget {
  const SellerOrderView({super.key});

  @override
  State<SellerOrderView> createState() => _SellerOrderViewState();
}

class _SellerOrderViewState extends State<SellerOrderView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SellerOrderCubit>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<SellerOrderCubit, SellerOrderState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const BuyerLoading(message: 'Đang tải danh sách đơn hàng...');
            }

            if (state.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SellerOrderCubit>().loadOrders(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildHeader(context),
                _buildSummaryCard(context, state),
                _buildStatusTabs(context, state),
                Expanded(child: _buildOrderList(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 24),
            color: const Color(0xFF1F2937),
          ),
          const Expanded(
            child: Text(
              'Đơn hàng của tôi',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF1F2937)),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, RouteName.chat),
            icon: const Icon(Icons.chat_bubble_outline, size: 24),
            color: const Color(0xFF1F2937),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, size: 24), color: const Color(0xFF1F2937)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune, size: 24), color: const Color(0xFF1F2937)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, SellerOrderState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2F8000), Color(0xFF2F8000)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng hôm nay', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xE6FFFFFF))),
              const SizedBox(height: 4),
              Text(_formatCurrency(state.totalToday), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white)),
            ],
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(BuildContext context, SellerOrderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _buildStatusTab(context, label: 'Chờ xác nhận', status: OrderStatus.pending, isActive: state.selectedTab == OrderStatus.pending, count: state.pendingCount),
          const SizedBox(width: 20),
          _buildStatusTab(context, label: 'Đang giao', status: OrderStatus.delivering, isActive: state.selectedTab == OrderStatus.delivering, count: state.deliveringCount),
          const SizedBox(width: 20),
          _buildStatusTab(context, label: 'Hoàn tất', status: OrderStatus.completed, isActive: state.selectedTab == OrderStatus.completed, count: state.completedCount),
        ],
      ),
    );
  }

  Widget _buildStatusTab(BuildContext context, {required String label, required OrderStatus status, required bool isActive, required int count}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SellerOrderCubit>().selectTab(status),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: isActive ? const Color(0xFF2F8000) : const Color(0xFF6B7280)), textAlign: TextAlign.center),
                ),
                if (isActive && count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2F8000), borderRadius: BorderRadius.circular(10)),
                    child: Text('$count', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isActive) Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF2F8000), borderRadius: BorderRadius.circular(1.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, SellerOrderState state) {
    final orders = state.filteredOrders;

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<SellerOrderCubit>().loadOrders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 16),
                  const Text('Không có đơn hàng', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Text(_getEmptyMessage(state.selectedTab), style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SellerOrderCubit>().loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildOrderCard(context, order)),
          );
        },
      ),
    );
  }

  String _getEmptyMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Chưa có đơn hàng chờ xác nhận';
      case OrderStatus.confirmed:
      case OrderStatus.delivering: return 'Chưa có đơn hàng đang giao';
      case OrderStatus.completed: return 'Chưa có đơn hàng hoàn tất';
      case OrderStatus.cancelled: return 'Chưa có đơn hàng đã hủy';
    }
  }


  Widget _buildOrderCard(BuildContext context, SellerOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderId, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(order.orderTime, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getStatusBgColor(order.status), borderRadius: BorderRadius.circular(8)),
                child: Text(_getStatusText(order.status), style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, color: _getStatusColor(order.status))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Customer Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]), borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.person, color: Color(0xFF6B7280), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customerName, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text(order.customerPhone, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Products Section
          const Text('Sản phẩm đã đặt', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          ...order.products.map((product) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(product.name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF4B5563)))),
                Text('x${product.quantity}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(width: 12),
                Text(_formatCurrency(product.total), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF1F2937))),
              ],
            ),
          )),
          // Address
          if (order.customerAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(child: Text(order.customerAddress, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          // Payment & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(order.paymentMethod == 'Tiền mặt' ? Icons.money : Icons.account_balance, size: 14, color: const Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(order.paymentMethod, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: order.isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                    child: Text(order.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: order.isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF6B7280))),
                  Text(_formatCurrency(order.amount), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF1F2937))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Actions
          Row(
            children: [
              Expanded(child: _buildContactButton(context, order)),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildRejectButton(context, order)),
              ],
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildConfirmButton(context, order)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, SellerOrder order) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:${order.customerPhone.replaceAll(' ', '')}');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.phone, size: 18, color: Color(0xFF4B5563)),
      ),
    );
  }

  Widget _buildRejectButton(BuildContext context, SellerOrder order) {
    return GestureDetector(
      onTap: () => _showRejectDialog(context, order),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Từ chối', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFDC2626))),
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, SellerOrder order) async {
    // Lưu cubit reference trước khi async
    final cubit = context.read<SellerOrderCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Lấy danh sách lý do từ chối từ API
    final reasons = await cubit.getRejectionReasons();
    if (!mounted) return;
    
    if (reasons.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể tải danh sách lý do từ chối'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? selectedReasonCode;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Từ chối đơn hàng', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đơn hàng: ${order.orderId}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                const Text('Chọn lý do từ chối:', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason.label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text(reason.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280))),
                  value: reason.code,
                  groupValue: selectedReasonCode,
                  activeColor: const Color(0xFFDC2626),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setDialogState(() => selectedReasonCode = value),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: selectedReasonCode != null
                  ? () {
                      Navigator.pop(dialogContext);
                      _handleRejectOrder(cubit, scaffoldMessenger, order, selectedReasonCode!);
                    }
                  : null,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRejectOrder(SellerOrderCubit cubit, ScaffoldMessengerState scaffoldMessenger, SellerOrder order, String reasonCode) async {
    final result = await cubit.rejectOrder(order.id, reasonCode: reasonCode);
    if (!mounted) return;
    
    if (result != null && result.success) {
      String message = result.message;
      if (result.lyDoHuy != null && result.lyDoHuy!.isNotEmpty) {
        message += '\nLý do: ${result.lyDoHuy}';
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildConfirmButton(BuildContext context, SellerOrder order) {
    final canConfirm = order.status == OrderStatus.pending;
    return GestureDetector(
      onTap: canConfirm ? () => _handleConfirmOrder(context, order) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: canConfirm ? [const Color(0xFF2F8000), const Color(0xFF2F8000)] : [Colors.grey, Colors.grey]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(canConfirm ? 'Xác nhận' : _getStatusText(order.status), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white))),
      ),
    );
  }

  Future<void> _handleConfirmOrder(BuildContext context, SellerOrder order) async {
    final cubit = context.read<SellerOrderCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final result = await cubit.confirmOrder(order.id);
    if (!mounted) return;
    
    if (result != null && result.success) {
      String message = result.message;
      if (result.shipperName != null && result.shipperName!.isNotEmpty) {
        message += '\nShipper: ${result.shipperName}';
        if (result.shipperPhone != null && result.shipperPhone!.isNotEmpty) {
          message += ' - ${result.shipperPhone}';
        }
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF2F8000),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (result != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Chờ xác nhận';
      case OrderStatus.confirmed: return 'Đã xác nhận';
      case OrderStatus.delivering: return 'Đang giao';
      case OrderStatus.completed: return 'Hoàn tất';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFD97706);
      case OrderStatus.confirmed: return const Color(0xFF2563EB);
      case OrderStatus.delivering: return const Color(0xFF7C3AED);
      case OrderStatus.completed: return const Color(0xFF059669);
      case OrderStatus.cancelled: return const Color(0xFFDC2626);
    }
  }

  Color _getStatusBgColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFFEF3C7);
      case OrderStatus.confirmed: return const Color(0xFFDBEAFE);
      case OrderStatus.delivering: return const Color(0xFFEDE9FE);
      case OrderStatus.completed: return const Color(0xFFD1FAE5);
      case OrderStatus.cancelled: return const Color(0xFFFEE2E2);
    }
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '$formatted₫';
  }
}
