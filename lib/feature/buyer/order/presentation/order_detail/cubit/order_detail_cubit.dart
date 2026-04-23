import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/config/app_config.dart';
import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/services/order_service.dart';
import '../../../../../../core/services/nguyen_lieu_service.dart';
import '../../../../../../core/dependency/injection.dart';

part 'order_detail_state.dart';

/// Cubit quản lý logic cho OrderDetail
/// 
/// Chức năng:
/// - Tải chi tiết đơn hàng
/// - Hủy đơn hàng
/// - Đặt lại đơn hàng
/// - Đánh giá đơn hàng
class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderService _orderService = OrderService();
  
  OrderDetailCubit() : super(const OrderDetailInitial());

  /// Tải chi tiết đơn hàng từ API
  Future<void> loadOrderDetail(String orderId) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Loading order detail for orderId: $orderId');
    }

    emit(const OrderDetailLoading());

    try {
      final response = await _orderService.getOrderDetail(orderId);
      var currentData = response.data;

      // Enrich images for items if missing
      try {
        final nguyenLieuService = getDependency<NguyenLieuService>();
        final enrichedItems = await Future.wait(currentData.items.map((item) async {
          if (item.nguyenLieu != null && (item.nguyenLieu!.hinhAnh == null || item.nguyenLieu!.hinhAnh!.isEmpty)) {
            try {
              final detail = await nguyenLieuService.getNguyenLieuDetail(item.maNguyenLieu);
              if (detail.data.hinhAnh != null && detail.data.hinhAnh!.isNotEmpty) {
                return item.copyWith(
                  nguyenLieu: item.nguyenLieu!.copyWith(hinhAnh: detail.data.hinhAnh),
                );
              }
            } catch (e) {
              AppLogger.warning('⚠️ [ORDER DETAIL] Could not fetch image for ${item.maNguyenLieu}: $e');
            }
          }
          return item;
        }));
        
        currentData = currentData.copyWith(items: enrichedItems);
      } catch (e) {
        AppLogger.error('❌ [ORDER DETAIL] Error enriching images: $e');
      }

      // Check if cubit is still open before continuing
      if (isClosed) return;

      if (AppConfig.enableApiLogging) {
        AppLogger.info('Order detail loaded successfully with enriched images');
      }

      emit(OrderDetailLoaded(orderDetail: currentData));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('Failed to load order detail: $e');
      }

      if (!isClosed) {
        emit(OrderDetailFailure(
          errorMessage: 'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.',
        ));
      }
    }
  }

  /// Hủy đơn hàng
  Future<void> cancelOrder(String orderId) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Cancelling order: $orderId');
    }

    emit(const OrderDetailProcessing());

    try {
      final response = await _orderService.cancelOrder(orderId);

      if (isClosed) return;

      if (AppConfig.enableApiLogging) {
        AppLogger.info('Order cancelled successfully: ${response.message}');
      }

      emit(OrderDetailCancelled(
        message: response.message,
        orderId: orderId,
        restoredItemsCount: response.soMatHang,
      ));

      // Reload order detail to show updated status
      await loadOrderDetail(orderId);
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('Failed to cancel order: $e');
      }

      if (!isClosed) {
        emit(OrderDetailFailure(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    }
  }

  /// Đặt lại đơn hàng
  Future<void> reorder(String orderId) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Reordering: $orderId');
    }

    emit(const OrderDetailProcessing());

    try {
      // TODO: Implement reorder API
      await Future.delayed(const Duration(seconds: 1));

      if (isClosed) return;

      final newOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      if (AppConfig.enableApiLogging) {
        AppLogger.info('Reorder successful, new order ID: $newOrderId');
      }

      emit(OrderDetailReordered(
        message: 'Đặt lại đơn hàng thành công',
        newOrderId: newOrderId,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('Failed to reorder: $e');
      }

      if (!isClosed) {
        emit(OrderDetailFailure(
          errorMessage: 'Không thể đặt lại đơn hàng. Vui lòng thử lại.',
        ));
      }
    }
  }

  /// Yêu cầu hoàn tiền
  Future<void> requestRefund(String orderId, List<RefundItem> items) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('Requesting refund for order: $orderId');
    }

    emit(const OrderDetailProcessing());

    try {
      final request = RefundRequest(orderId: orderId, items: items);
      await _orderService.refundOrder(request);

      if (isClosed) return;

      if (AppConfig.enableApiLogging) {
        AppLogger.info('Refund requested successfully for $orderId');
      }

      emit(OrderDetailRefundSuccess(
        message: 'Yêu cầu hoàn tiền thành công',
        orderId: orderId,
      ));

      // Reload order detail
      await loadOrderDetail(orderId);
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('Failed to request refund: $e');
      }

      if (!isClosed) {
        emit(OrderDetailFailure(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    }
  }
}
