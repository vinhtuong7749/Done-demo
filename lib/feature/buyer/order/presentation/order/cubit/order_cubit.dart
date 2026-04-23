import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/config/app_config.dart';
import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/services/order_service.dart';
import '../../../../../../core/utils/status_formatter.dart';

part 'order_state.dart';

/// Cubit quản lý logic cho Order
/// 
/// Chức năng:
/// - Tải danh sách đơn hàng
/// - Lọc đơn hàng theo trạng thái
/// - Mở rộng/thu gọn chi tiết đơn hàng
class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService = OrderService();
  
  OrderCubit() : super(const OrderInitial());

  List<Order> _allOrders = [];
  OrderFilterType _currentFilter = OrderFilterType.all;

  Future<void> loadOrders() async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Loading orders from API');
    }

    emit(const OrderLoading());

    try {
      // Gọi API để lấy danh sách đơn hàng với limit lớn nhất được phép (áp dụng cho filter local ở máy khách)
      final response = await _orderService.getOrders(page: 1, limit: 100);

      // Check if cubit is still open before continuing
      if (isClosed) return;

      // Convert API response to Order list
      _allOrders = response.items.map((orderModel) {
        return Order(
          orderId: orderModel.maDonHang,
          shopName: orderModel.diaChiGiaoHang?.name ?? 'Đơn hàng',
          items: [], // Items sẽ được load khi xem chi tiết
          totalAmount: orderModel.tongTien,
          status: _mapOrderStatus(orderModel.tinhTrangDonHang),
          orderDate: orderModel.thoiGianGiaoHang ?? DateTime.now(),
          paymentStatus: orderModel.thanhToan?.tinhTrangThanhToan,
          paymentMethod: orderModel.thanhToan?.hinhThucThanhToan,
        );
      }).toList();

      if (AppConfig.enableApiLogging) {
        AppLogger.info('Orders loaded successfully: ${_allOrders.length} orders');
      }

      _emitFilteredOrders();
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('Failed to load orders: $e');
      }

      if (!isClosed) {
        emit(OrderFailure(
          errorMessage: 'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
        ));
      }
    }
  }

  /// Map trạng thái đơn hàng từ API sang enum
  OrderStatusType _mapOrderStatus(String status) {
    switch (status) {
      case 'cho_xac_nhan':
      case 'chua_xac_nhan':
        return OrderStatusType.pending;
      case 'da_xac_nhan':
        return OrderStatusType.processing;
      case 'dang_giao':
        return OrderStatusType.shipping;
      case 'da_giao':
      case 'hoan_thanh':
        return OrderStatusType.delivered;
      case 'da_huy':
        return OrderStatusType.cancelled;
      default:
        return OrderStatusType.pending;
    }
  }

  /// Lọc đơn hàng theo trạng thái
  void filterOrders(OrderFilterType filterType) {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Filtering orders by: ${filterType.displayName}');
    }

    _currentFilter = filterType;
    _emitFilteredOrders();
  }

  /// Mở rộng/thu gọn đơn hàng
  void toggleOrderExpansion(String orderId) {
    final updatedOrders = _allOrders.map((order) {
      if (order.orderId == orderId) {
        return order.copyWith(isExpanded: !order.isExpanded);
      }
      return order;
    }).toList();

    _allOrders = updatedOrders;
    _emitFilteredOrders();
  }

  /// Emit danh sách đơn hàng đã lọc
  void _emitFilteredOrders() {
    List<Order> filteredOrders;

    switch (_currentFilter) {
      case OrderFilterType.all:
        filteredOrders = _allOrders;
        break;
      case OrderFilterType.pending:
        filteredOrders = _allOrders
            .where((order) => order.status == OrderStatusType.pending)
            .toList();
        break;
      case OrderFilterType.processing:
        filteredOrders = _allOrders
            .where((order) => order.status == OrderStatusType.processing)
            .toList();
        break;
      case OrderFilterType.shipping:
        filteredOrders = _allOrders
            .where((order) => order.status == OrderStatusType.shipping)
            .toList();
        break;
      case OrderFilterType.delivered:
        filteredOrders = _allOrders
            .where((order) => order.status == OrderStatusType.delivered)
            .toList();
        break;
    }

    // Calculate counts for each status
    final pendingCount = _allOrders
        .where((order) => order.status == OrderStatusType.pending)
        .length;
    final processingCount = _allOrders
        .where((order) => order.status == OrderStatusType.processing)
        .length;
    final shippingCount = _allOrders
        .where((order) => order.status == OrderStatusType.shipping)
        .length;
    final deliveredCount = _allOrders
        .where((order) => order.status == OrderStatusType.delivered)
        .length;

    emit(OrderLoaded(
      orders: filteredOrders,
      filterType: _currentFilter,
      pendingCount: pendingCount,
      processingCount: processingCount,
      shippingCount: shippingCount,
      deliveredCount: deliveredCount,
    ));
  }

}
