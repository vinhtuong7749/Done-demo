import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/order_cubit.dart';
import '../../order_detail/screen/order_detail_page.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/buyer_loading.dart';

/// Màn hình đơn hàng
/// 
/// Chức năng:
/// - Hiển thị danh sách đơn hàng
/// - Lọc đơn hàng theo trạng thái
/// - Xem chi tiết đơn hàng
/// - Quản lý thông tin người dùng
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  static const String routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderCubit()..loadOrders(),
      child: const OrderView(),
    );
  }
}

/// View của màn hình đơn hàng
class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6), // Stitch Mint
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            Expanded(
              child: BlocBuilder<OrderCubit, OrderState>(
                builder: (context, state) {
                  if (state is OrderLoading) {
                    return const BuyerLoading(
              message: 'Đang tải đơn hàng...',
            );
                  }

                  if (state is OrderLoaded) {
                    return _buildContent(context, state);
                  }

                  if (state is OrderFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFFFF0000),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            
            
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF000000),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Color(0xFF26CD3A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Đơn hàng của tôi',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Color(0xFF1B5E20), // Forest Green
            ),
          ),
        ],
      ),
    );
  }

  /// Header
  

  /// Content
  Widget _buildContent(BuildContext context, OrderLoaded state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Status filter tabs
          _buildStatusTabs(context, state),
          
          const SizedBox(height: 20),
          
          // Recent orders section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF26CD3A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Gần đây',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1B5E20), // Forest Green
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Orders list
          if (state.orders.isEmpty)
            _buildEmptyState()
          else
            ...state.orders.map((order) => _buildOrderCard(context, order)),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Status filter tabs
  Widget _buildStatusTabs(BuildContext context, OrderLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildStatusTab(
            context,
            'Chờ Xác Nhận',
            state.pendingCount.toString(),
            OrderFilterType.pending,
            state.filterType == OrderFilterType.pending,
          ),
          const SizedBox(width: 7),
          _buildStatusTab(
            context,
            'Đang Xử Lý',
            state.processingCount.toString(),
            OrderFilterType.processing,
            state.filterType == OrderFilterType.processing,
          ),
          const SizedBox(width: 7),
          _buildStatusTab(
            context,
            'Đang Giao',
            state.shippingCount.toString(),
            OrderFilterType.shipping,
            state.filterType == OrderFilterType.shipping,
          ),
          const SizedBox(width: 7),
          _buildStatusTab(
            context,
            'Giao Thành Công',
            state.deliveredCount.toString(),
            OrderFilterType.delivered,
            state.filterType == OrderFilterType.delivered,
          ),
        ],
      ),
    );
  }

  /// Status tab
  Widget _buildStatusTab(
    BuildContext context,
    String label,
    String count,
    OrderFilterType filterType,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<OrderCubit>().filterOrders(filterType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF26CD3A).withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF26CD3A)
                  : Colors.transparent,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Count
              Text(
                count,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: isSelected ? const Color(0xFF26CD3A) : const Color(0xFF1C1C1E),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Label
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: -0.16,
                      color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF8E8E93),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Order card
  Widget _buildOrderCard(BuildContext context, Order order) {
    return GestureDetector(
      onTap: () {
        // Navigate to order detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderId: order.orderId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: Color(0xFF26CD3A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date row
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.orderDate),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Divider
            Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.08),
            ),
            
            const SizedBox(height: 12),
            
                // Payment status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      order.isPaid ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: order.isPaid ? const Color(0xFF26CD3A) : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.paymentStatusDisplay,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: order.isPaid ? const Color(0xFF26CD3A) : Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                // Total amount
                Text(
                  '${_formatPrice(order.totalAmount)}đ',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFFE53935), // Red pricing for orders
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(OrderStatusType status) {
    switch (status) {
      case OrderStatusType.pending:
        return Colors.orange;
      case OrderStatusType.processing:
        return Colors.blue;
      case OrderStatusType.shipping:
        return const Color(0xFF1B5E20); // Darker forest green
      case OrderStatusType.delivered:
        return const Color(0xFF26CD3A); // Bright primary green
      case OrderStatusType.cancelled:
        return Colors.red;
    }
  }



  

  /// Format price helper
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Format date time
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }
}
