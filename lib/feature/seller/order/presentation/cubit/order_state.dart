import 'package:equatable/equatable.dart';
import '../../../../../core/models/seller_order_model.dart';

enum OrderStatus {
  pending,        // Chờ xác nhận  (chua_xac_nhan)
  waitingShipper, // Chờ shipper   (da_xac_nhan) - seller đã xác nhận, chờ shipper tới lấy
  delivering,     // Đang giao      (dang_giao)  - shipper đang giao
  completed,      // Hoàn tất        (hoan_tat)
  cancelled,      // Đã hủy          (da_huy)
}

/// Convert từ API status string sang enum
OrderStatus parseOrderStatus(String status) {
  switch (status.toLowerCase()) {
    case 'chua_xac_nhan':
    case 'cho_xac_nhan':
      return OrderStatus.pending;
    case 'da_xac_nhan':
    case 'da_duyet':
    case 'da_xac_nhan_1_phan':
    case 'cho_shipper':
    case 'dang_tim_shipper':
    case 'cho_lay_hang':
      return OrderStatus.waitingShipper;  // Seller đã xác nhận, chờ shipper
    case 'dang_giao':
    case 'da_giao_shipper':
      return OrderStatus.delivering;
    case 'hoan_tat':
    case 'da_giao':
    case 'completed':
      return OrderStatus.completed;
    case 'da_huy':
    case 'huy':
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      // Bất kỳ status nào không rõ -> phân là pending để không bị mất
      return OrderStatus.pending;
  }
}

class OrderProduct extends Equatable {
  final String maNguyenLieu;
  final String name;
  final int quantity;
  final double price;
  final double total;

  const OrderProduct({
    required this.maNguyenLieu,
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  List<Object?> get props => [maNguyenLieu, name, quantity, price, total];
}

class SellerOrder extends Equatable {
  final String id;
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String orderTime;
  final List<OrderProduct> products;
  final double amount;
  final OrderStatus status;
  final String paymentMethod;
  final bool isPaid;

  const SellerOrder({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.orderTime,
    required this.products,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
  });

  /// Tạo từ API model
  factory SellerOrder.fromApiModel(SellerOrderModel model) {
    return SellerOrder(
      id: model.maDonHang,
      orderId: model.maDonHang,
      customerName: model.diaChiGiaoHang?.name ?? model.nguoiMua?.tenNguoiDung ?? 'Khách hàng',
      customerPhone: model.diaChiGiaoHang?.phone ?? model.nguoiMua?.sdt ?? '',
      customerAddress: model.diaChiGiaoHang?.address ?? '',
      orderTime: _formatOrderTime(model.thoiGianGiaoHang),
      products: model.chiTietDonHang.map((item) => OrderProduct(
        maNguyenLieu: item.maNguyenLieu,
        name: item.tenNguyenLieu,
        quantity: item.soLuong,
        price: item.giaCuoi,
        total: item.thanhTien,
      )).toList(),
      amount: model.tongTien,
      status: parseOrderStatus(model.tinhTrangDonHang),
      paymentMethod: model.thanhToan?.hinhThucText ?? '',
      isPaid: model.thanhToan?.daThanhToan ?? false,
    );
  }

  static String _formatOrderTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  List<Object?> get props => [id, orderId, customerName, customerPhone, customerAddress, orderTime, products, amount, status, paymentMethod, isPaid];
}

class SellerOrderState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<SellerOrder> orders;
  final double totalToday;
  final int selectedNavIndex;
  final OrderStatus selectedTab;
  // --- Thông báo đơn hàng mới ---
  final bool hasNewOrder;
  final int newOrderCount;

  const SellerOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
    this.totalToday = 0,
    this.selectedNavIndex = 0,
    this.selectedTab = OrderStatus.pending,
    this.hasNewOrder = false,
    this.newOrderCount = 0,
  });

  /// Factory method để tạo state rỗng
  factory SellerOrderState.initial() {
    return const SellerOrderState(
      isLoading: true,
      selectedTab: OrderStatus.pending,
    );
  }

  SellerOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<SellerOrder>? orders,
    double? totalToday,
    int? selectedNavIndex,
    OrderStatus? selectedTab,
    bool? hasNewOrder,
    int? newOrderCount,
  }) {
    return SellerOrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
      totalToday: totalToday ?? this.totalToday,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      selectedTab: selectedTab ?? this.selectedTab,
      hasNewOrder: hasNewOrder ?? this.hasNewOrder,
      newOrderCount: newOrderCount ?? this.newOrderCount,
    );
  }

  List<SellerOrder> get filteredOrders {
    switch (selectedTab) {
      case OrderStatus.pending:
        return orders.where((o) => o.status == OrderStatus.pending).toList();
      case OrderStatus.waitingShipper:
        return orders.where((o) => o.status == OrderStatus.waitingShipper).toList();
      case OrderStatus.delivering:
        return orders.where((o) => o.status == OrderStatus.delivering).toList();
      case OrderStatus.completed:
        return orders.where((o) => o.status == OrderStatus.completed).toList();
      case OrderStatus.cancelled:
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
    }
  }

  int get pendingCount => orders.where((o) => o.status == OrderStatus.pending).length;
  int get waitingShipperCount => orders.where((o) => o.status == OrderStatus.waitingShipper).length;
  int get deliveringCount => orders.where((o) => o.status == OrderStatus.delivering).length;
  int get completedCount => orders.where((o) => o.status == OrderStatus.completed).length;

  @override
  List<Object?> get props => [isLoading, errorMessage, orders, totalToday, selectedNavIndex, selectedTab, hasNewOrder, newOrderCount];
}
