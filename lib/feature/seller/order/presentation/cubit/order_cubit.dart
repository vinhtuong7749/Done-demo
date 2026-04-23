import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_state.dart';
import '../../../../../core/services/seller_order_service.dart';

import '../../../../../core/models/seller_order_model.dart';

/// Kết quả xác nhận đơn hàng
class ConfirmOrderResult {
  final bool success;
  final String message;
  final String? shipperName;
  final String? shipperPhone;

  ConfirmOrderResult({
    required this.success,
    required this.message,
    this.shipperName,
    this.shipperPhone,
  });
}

/// Kết quả từ chối đơn hàng
class RejectOrderResult {
  final bool success;
  final String message;
  final String? lyDoHuy;

  RejectOrderResult({
    required this.success,
    required this.message,
    this.lyDoHuy,
  });
}

class SellerOrderCubit extends Cubit<SellerOrderState> {
  final SellerOrderService _orderService = SellerOrderService();

  // --- Polling để nhận đơn hàng mới ---
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);

  SellerOrderCubit() : super(SellerOrderState.initial());

  /// Bắt đầu polling tự động khi màn hình order được mở
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      debugPrint('🔄 [SELLER POLLING] Checking for new orders...');
      await _checkForNewOrders();
    });
    debugPrint('✅ [SELLER POLLING] Started (interval: ${_pollingInterval.inSeconds}s)');
  }

  /// Dừng polling khi màn hình bị đóng
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('🛑 [SELLER POLLING] Stopped');
  }

  /// Kiểm tra đơn hàng mới mà không hiển thị loading
  Future<void> _checkForNewOrders() async {
    if (isClosed) return;
    try {
      final response = await _orderService.getOrders(limit: 50);
      if (!response.success || isClosed) return;

      final rawOrders = response.items.map((item) => SellerOrder.fromApiModel(item)).toList();
      final orders = rawOrders.where((order) {
        final pm = order.paymentMethod.toLowerCase().trim();
        final isOnlinePayment = pm == 'chuyen_khoan' || pm == 'vnpay' || pm == 'online';
        if (isOnlinePayment && !order.isPaid) return false;
        return true;
      }).toList();

      final currentPendingIds = state.orders
          .where((o) => o.status == OrderStatus.pending)
          .map((o) => o.id)
          .toSet();
      final newPendingOrders = orders
          .where((o) =>
              o.status == OrderStatus.pending &&
              !currentPendingIds.contains(o.id))
          .toList();

      if (newPendingOrders.isNotEmpty) {
        debugPrint('🆕 [SELLER POLLING] ${newPendingOrders.length} new order(s) detected!');
        final today = DateTime.now();
        final todayOrders = orders.where((item) {
          final rawItem = response.items.firstWhere((r) => r.maDonHang == item.id, orElse: () => response.items.first);
          final time = rawItem.thoiGianGiaoHang;
          if (time == null) return false;
          return time.year == today.year &&
              time.month == today.month &&
              time.day == today.day;
        });
        final totalToday =
            todayOrders.fold<double>(0, (sum, item) => sum + item.amount);

        emit(state.copyWith(
          orders: orders,
          totalToday: totalToday,
          newOrderCount: newPendingOrders.length,
          hasNewOrder: true,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [SELLER POLLING] Check error: $e');
    }
  }

  /// Reset trạng thái đơn hàng mới (sau khi đã thông báo)
  void clearNewOrderNotification() {
    emit(state.copyWith(hasNewOrder: false, newOrderCount: 0));
  }

  Future<void> loadOrders() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _orderService.getOrders(limit: 50);
      
      if (response.success) {
        final rawOrders = response.items.map((item) => SellerOrder.fromApiModel(item)).toList();
        
        // Giữ lại TấT CẢ đơn hàng (kể cả khi API không trả về thông tin thanh toán).
        // Chỉ ẩn đơn "thanh toán online (chuyen_khoan/vnpay) + CHƯА thanh toán".
        // Nếu paymentMethod rỗng (API không trả) -> cũng hiển thị.
        final orders = rawOrders.where((order) {
          final pm = order.paymentMethod.toLowerCase().trim();
          // Ẩn đơn hàng thanh toán online chưa thành công
          final isOnlinePayment = pm == 'chuyen_khoan' || pm == 'vnpay' || pm == 'online';
          if (isOnlinePayment && !order.isPaid) return false;
          return true;
        }).toList();
        
        // Tính tổng tiền hôm nay (đơn hàng trong ngày)
        final today = DateTime.now();
        final todayOrders = orders.where((item) {
          final rawItem = response.items.firstWhere((r) => r.maDonHang == item.id, orElse: () => response.items.first);
          final time = rawItem.thoiGianGiaoHang;
          if (time == null) return false;
          return time.year == today.year &&
                 time.month == today.month &&
                 time.day == today.day;
        });
        final totalToday = todayOrders.fold<double>(0, (sum, item) => sum + item.amount);

        emit(state.copyWith(
          isLoading: false,
          orders: orders,
          totalToday: totalToday,
          hasNewOrder: false,
          newOrderCount: 0,
        ));
        
        debugPrint('✅ [SELLER ORDER] Loaded ${orders.length} orders (from ${rawOrders.length} raw)');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách đơn hàng',
        ));
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách đơn hàng: $e',
      ));
    }
  }

  void selectTab(OrderStatus tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  /// Xác nhận đơn hàng và trả về response
  Future<ConfirmOrderResult?> confirmOrder(String orderId, {List<String> ingredientIds = const []}) async {
    try {
      final response = await _orderService.confirmOrder(orderId, ingredientIds: ingredientIds);
      
      if (response.success) {
        await loadOrders();
        return ConfirmOrderResult(
          success: true,
          message: response.message,
          shipperName: response.shipperAssigned?.tenShipper,
          shipperPhone: response.shipperAssigned?.sdt,
        );
      }
      return ConfirmOrderResult(success: false, message: response.message);
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Confirm error: $e');
      return ConfirmOrderResult(success: false, message: 'Có lỗi xảy ra: $e');
    }
  }

  /// Lấy danh sách lý do từ chối
  Future<List<RejectionReason>> getRejectionReasons() async {
    try {
      final response = await _orderService.getRejectionReasons();
      if (response.success) {
        return response.reasons;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Get rejection reasons error: $e');
      return [];
    }
  }

  /// Từ chối đơn hàng
  Future<RejectOrderResult?> rejectOrder(String orderId, {required String reasonCode}) async {
    try {
      final response = await _orderService.rejectOrder(orderId, reasonCode: reasonCode);
      
      if (response.success) {
        await loadOrders();
        return RejectOrderResult(
          success: true,
          message: response.message,
          lyDoHuy: response.lyDoHuy,
        );
      }
      return RejectOrderResult(success: false, message: response.message);
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Reject error: $e');
      return RejectOrderResult(success: false, message: 'Có lỗi xảy ra: $e');
    }
  }

  void setSelectedNavIndex(int index) {
    emit(state.copyWith(selectedNavIndex: index));
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
