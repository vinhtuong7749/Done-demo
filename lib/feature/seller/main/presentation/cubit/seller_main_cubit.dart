import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/services/seller_order_service.dart';

part 'seller_main_state.dart';

/// Cubit quản lý tab navigation + global new-order polling cho Seller Main Screen
class SellerMainCubit extends Cubit<SellerMainState> {
  final SellerOrderService _orderService = SellerOrderService();

  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 20);

  // Lưu lại danh sách ID đơn hàng đã biết để so sánh
  Set<String> _knownOrderIds = {};
  bool _initialized = false;

  SellerMainCubit({int initialIndex = 0})
      : super(SellerMainState.initial(currentIndex: initialIndex));

  /// Khởi động polling ngay khi seller login vào app
  void startGlobalPolling() {
    if (_pollingTimer != null) return; // Tránh khởi động 2 lần
    _loadInitialOrderIds();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkForNewOrders();
    });
    debugPrint('✅ [GLOBAL POLLING] Started (interval: ${_pollingInterval.inSeconds}s)');
  }

  /// Dừng polling khi logout
  void stopGlobalPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _initialized = false;
    _knownOrderIds = {};
    debugPrint('🛑 [GLOBAL POLLING] Stopped');
  }

  /// Lần đầu tải danh sách đơn hàng — lưu làm baseline để so sánh
  Future<void> _loadInitialOrderIds() async {
    try {
      final response = await _orderService.getOrders(limit: 50);
      if (response.success) {
        _knownOrderIds = response.items.map((o) => o.maDonHang).toSet();
        _initialized = true;
        debugPrint('📋 [GLOBAL POLLING] Baseline: ${_knownOrderIds.length} orders loaded');
      }
    } catch (e) {
      debugPrint('⚠️ [GLOBAL POLLING] Init error: $e');
    }
  }

  /// Kiểm tra đơn hàng mới bằng cách so sánh với baseline
  Future<void> _checkForNewOrders() async {
    if (isClosed || !_initialized) return;
    try {
      final response = await _orderService.getOrders(limit: 50);
      if (!response.success || isClosed) return;

      // Lấy các đơn hàng chờ xác nhận mà chưa biết
      final newOrders = response.items.where((o) {
        return o.tinhTrangDonHang == 'chua_xac_nhan' &&
               !_knownOrderIds.contains(o.maDonHang);
      }).toList();

      if (newOrders.isNotEmpty) {
        debugPrint('🆕 [GLOBAL POLLING] ${newOrders.length} new order(s) detected!');
        // Cập nhật baseline
        _knownOrderIds.addAll(response.items.map((o) => o.maDonHang));

        final currentCount = state.pendingOrderCount + newOrders.length;
        emit(state.copyWith(
          pendingOrderCount: currentCount,
          hasNewOrder: true,
          newOrderCount: newOrders.length,
        ));
      } else {
        // Cập nhật baseline khi không có đơn mới (đề phòng đơn bị hủy/xóa)
        _knownOrderIds = response.items.map((o) => o.maDonHang).toSet();
      }
    } catch (e) {
      debugPrint('⚠️ [GLOBAL POLLING] Check error: $e');
    }
  }

  /// Reset thông báo đơn hàng mới sau khi user đã thấy
  void clearNewOrderNotification() {
    emit(state.copyWith(hasNewOrder: false, newOrderCount: 0));
  }

  /// Reset badge số lượng đơn hàng khi vào tab đơn hàng
  void clearPendingBadge() {
    emit(state.copyWith(pendingOrderCount: 0));
  }

  /// Chuyển tab
  void changeTab(int index) {
    // Khi vào tab Đơn hàng (index=2), xóa badge
    if (index == 2) {
      emit(state.copyWith(
        currentIndex: index,
        hasNewOrder: false,
        newOrderCount: 0,
        pendingOrderCount: 0,
      ));
    } else {
      if (index != state.currentIndex) {
        emit(state.copyWith(currentIndex: index));
      }
    }
  }

  @override
  Future<void> close() {
    stopGlobalPolling();
    return super.close();
  }
}
