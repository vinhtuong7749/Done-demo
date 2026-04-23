part of 'seller_main_cubit.dart';

/// State cho Seller Main Screen (kèm thông báo đơn hàng mới)
class SellerMainState extends Equatable {
  final int currentIndex;
  final bool hasNewOrder;       // Có đơn mới cần thông báo
  final int newOrderCount;      // Số đơn mới vừa phát hiện
  final int pendingOrderCount;  // Tổng đơn chờ xác nhận (badge trên tab)

  const SellerMainState({
    required this.currentIndex,
    this.hasNewOrder = false,
    this.newOrderCount = 0,
    this.pendingOrderCount = 0,
  });

  factory SellerMainState.initial({int currentIndex = 0}) {
    return SellerMainState(currentIndex: currentIndex);
  }

  SellerMainState copyWith({
    int? currentIndex,
    bool? hasNewOrder,
    int? newOrderCount,
    int? pendingOrderCount,
  }) {
    return SellerMainState(
      currentIndex: currentIndex ?? this.currentIndex,
      hasNewOrder: hasNewOrder ?? this.hasNewOrder,
      newOrderCount: newOrderCount ?? this.newOrderCount,
      pendingOrderCount: pendingOrderCount ?? this.pendingOrderCount,
    );
  }

  @override
  List<Object?> get props => [currentIndex, hasNewOrder, newOrderCount, pendingOrderCount];
}
