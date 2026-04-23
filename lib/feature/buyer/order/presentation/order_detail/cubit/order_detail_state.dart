part of 'order_detail_cubit.dart';

/// Base state cho OrderDetail
abstract class OrderDetailState extends Equatable {
  const OrderDetailState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class OrderDetailInitial extends OrderDetailState {
  const OrderDetailInitial();
}

/// State đang tải dữ liệu
class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

/// State đã tải dữ liệu thành công - sử dụng OrderDetailData từ service
class OrderDetailLoaded extends OrderDetailState {
  final OrderDetailData orderDetail;

  const OrderDetailLoaded({
    required this.orderDetail,
  });

  @override
  List<Object?> get props => [orderDetail];
}

/// State đang xử lý thao tác (hủy đơn, đặt lại)
class OrderDetailProcessing extends OrderDetailState {
  const OrderDetailProcessing();
}

/// State hủy đơn thành công
class OrderDetailCancelled extends OrderDetailState {
  final String message;
  final String orderId;
  final int restoredItemsCount;

  const OrderDetailCancelled({
    required this.message,
    required this.orderId,
    this.restoredItemsCount = 0,
  });

  @override
  List<Object?> get props => [message, orderId, restoredItemsCount];
}

/// State đặt lại đơn hàng thành công
class OrderDetailReordered extends OrderDetailState {
  final String message;
  final String newOrderId;

  const OrderDetailReordered({
    required this.message,
    required this.newOrderId,
  });

  @override
  List<Object?> get props => [message, newOrderId];
}

/// State thất bại
class OrderDetailFailure extends OrderDetailState {
  final String errorMessage;

  const OrderDetailFailure({
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [errorMessage];
}

/// State yêu cầu hoàn tiền thành công
class OrderDetailRefundSuccess extends OrderDetailState {
  final String message;
  final String orderId;

  const OrderDetailRefundSuccess({
    required this.message,
    required this.orderId,
  });

  @override
  List<Object?> get props => [message, orderId];
}
