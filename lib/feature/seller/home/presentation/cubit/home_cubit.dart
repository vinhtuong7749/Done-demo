import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/auth/auth_service.dart';
import '../../../../../core/services/seller_order_service.dart';
import '../../../../../core/services/nhom_nguyen_lieu_service.dart';
import '../../../../../core/services/revenue_service.dart';
import '../../../../../core/services/gian_hang_service.dart';
import '../../../../../core/services/local_storage_service.dart';
import 'home_state.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/seller_order_model.dart' as model;

class SellerHomeCubit extends Cubit<SellerHomeState> {
  final AuthService _authService = AuthService();
  final SellerOrderService _orderService = SellerOrderService();
  final RevenueService _revenueService = RevenueService();
  final GianHangService _shopService = GianHangService();
  final LocalStorageService _localStorageService = LocalStorageService();

  SellerHomeCubit() : super(SellerHomeState.initial());

  Future<void> initializeHome() async {
    emit(state.copyWith(isLoading: true));

    try {
      // 1. Lấy thông tin shop (user name và trạng thái gian hàng)
      String shopName = 'Cửa hàng của bạn';
      bool isStoreOpen = state.isStoreOpen; // Giữ giá trị hiện tại làm mặc định
      String? maGianHang;

      try {
        final user = await _authService.getCurrentUser();
        shopName = user.tenNguoiDung.isNotEmpty ? user.tenNguoiDung : user.tenDangNhap;

        // Thử lấy shop status từ local storage dựa trên user_id trước (fallback)
        final savedUserStatus = _localStorageService.getShopStatus(user.maNguoiDung);
        if (savedUserStatus != null) {
          isStoreOpen = (savedUserStatus == 'mo_cua' || savedUserStatus == 'dang_mo_cua');
          debugPrint('🏪 [HOME_CUBIT] Found saved status for USER: $savedUserStatus (isStoreOpen: $isStoreOpen)');
        }

        // Lấy mã gian hàng từ sản phẩm đầu tiên để fetch chi tiết gian hàng
        final productsResponse = await NhomNguyenLieuService.getSellerProducts(limit: 1);
        if (productsResponse.data.isNotEmpty) {
          maGianHang = productsResponse.data[0]['ma_gian_hang'];
          if (maGianHang != null) {
            // Kiểm tra trạng thái lưu local theo maGianHang
            final savedStatus = _localStorageService.getShopStatus(maGianHang!);
            if (savedStatus != null) {
              isStoreOpen = (savedStatus == 'mo_cua' || savedStatus == 'dang_mo_cua');
              debugPrint('🏪 [HOME_CUBIT] Found saved status in local (Init): $savedStatus (isStoreOpen: $isStoreOpen)');
            }

            try {
              final shopDetail = await _shopService.getShopDetail(maGianHang!);
              if (shopDetail.success) {
                final apiStatus = shopDetail.detail.tinhTrang;
                final apiIsStoreOpen = (apiStatus == 'mo_cua' || apiStatus == 'dang_mo_cua');
                
                // Đồng bộ lại local storage
                await _localStorageService.saveShopStatus(maGianHang!, apiIsStoreOpen ? 'mo_cua' : 'dong_cua');
                await _localStorageService.saveShopStatus(user.maNguoiDung, apiIsStoreOpen ? 'mo_cua' : 'dong_cua');
                
                isStoreOpen = apiIsStoreOpen;
                debugPrint('🏪 [HOME_CUBIT] Initialized from API: $apiStatus (isStoreOpen: $isStoreOpen)');
              }
            } catch (e) {
              debugPrint('⚠️ [HOME_CUBIT] API Shop Detail failed, keeping local/default status. Error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [HOME_CUBIT] Error in shop initialization: $e');
      }

      // 2. Lấy danh sách đơn hàng để tính toán thống kê và đơn hàng mới
      final ordersResponse = await _orderService.getOrders(limit: 50);
      
      double todayRevenue = 0;
      int todayOrderCount = 0;
      int pendingOrderCount = 0;
      List<dynamic> recentOrders = [];

      if (ordersResponse.success) {
        final now = DateTime.now();
        recentOrders = ordersResponse.items.take(5).toList();

        for (final order in ordersResponse.items) {
          // Tính đơn hàng chờ xác nhận
          if (order.tinhTrangDonHang == 'cho_xac_nhan') {
            pendingOrderCount++;
          }

          // Tính thống kê hôm nay
          if (order.thoiGianGiaoHang != null) {
            final orderDate = order.thoiGianGiaoHang!;
            if (orderDate.year == now.year &&
                orderDate.month == now.month &&
                orderDate.day == now.day) {
              todayRevenue += order.tongTien;
              todayOrderCount++;
            }
          }
        }
      }

      // 3. Lấy thông tin sản phẩm và lọc hàng sắp hết
      final productsResponse = await NhomNguyenLieuService.getSellerProducts(limit: 100);
      int totalProducts = 0;
      int activeProducts = 0;
      List<dynamic> lowStockProducts = [];

      if (productsResponse.data.isNotEmpty) {
        totalProducts = productsResponse.meta.total;
        for (var prod in productsResponse.data) {
          activeProducts++; // Giả định tất cả trong danh sách là đang bán
          final stock = prod['so_luong_ban'] ?? 0;
          if (stock <= 5) {
            lowStockProducts.add(prod);
          }
        }
      }

      // 4. Lấy dữ liệu doanh thu 7 ngày gần đây để vẽ biểu đồ
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 6));
      final df = DateFormat('yyyy-MM-dd');
      
      Map<String, double> weeklyRevenue = {
        'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0
      };

      try {
        final revenueResult = await _revenueService.getRevenue(
          fromDate: df.format(start),
          toDate: df.format(end),
        );

        // Lấy mã gian hàng từ dữ liệu doanh thu nếu chưa có
        if (maGianHang == null && revenueResult.containsKey('stall_id')) {
          maGianHang = revenueResult['stall_id']?.toString();
          debugPrint('🏪 [HOME_CUBIT] Got maGianHang from Revenue: $maGianHang');
          
          if (maGianHang != null) {
            // 1. Kiểm tra trạng thái lưu local trước (để đảm bảo tính nhất quán trên thiết bị)
            final savedStatus = _localStorageService.getShopStatus(maGianHang!);
            if (savedStatus != null) {
              isStoreOpen = (savedStatus == 'mo_cua' || savedStatus == 'dang_mo_cua');
              debugPrint('🏪 [HOME_CUBIT] Found saved status in local: $savedStatus (isStoreOpen: $isStoreOpen)');
            }

            // 2. Vẫn fetch lại từ API để sync nếu server có hỗ trợ trả về status (fallback)
            final shopDetail = await _shopService.getShopDetail(maGianHang!);
            if (shopDetail.success) {
              // Chỉ ghi đè nếu API thực sự trả về một giá trị hợp lệ (không phải null)
              final apiStatus = shopDetail.detail.tinhTrang;
              final apiIsStoreOpen = (apiStatus == 'mo_cua' || apiStatus == 'dang_mo_cua');
              
              // Đồng bộ lại local storage với server
              await _localStorageService.saveShopStatus(maGianHang!, apiIsStoreOpen ? 'mo_cua' : 'dong_cua');
              
              isStoreOpen = apiIsStoreOpen;
              debugPrint('🏪 [HOME_CUBIT] Synced from API (Revenue Flow): $apiStatus (isStoreOpen: $isStoreOpen)');
            }
          }
        }

        if (revenueResult.containsKey('chi_tiet')) {
          final List<dynamic> details = revenueResult['chi_tiet'];
          for (var item in details) {
            final dateStr = item['ngay'] as String;
            final amount = (item['doanh_thu'] as num).toDouble();
            final date = DateTime.parse(dateStr);
            final dayLabel = _getDayLabel(date);
            weeklyRevenue[dayLabel] = amount;
          }
        }
      } catch (e) {
        // Log revenue Error
      }

      // 5. Tính toán phần trăm thay đổi doanh thu so với hôm qua
      double revenueChangePercentage = 0;
      final yesterday = end.subtract(const Duration(days: 1));
      final yesterdayLabel = _getDayLabel(yesterday);
      final yesterdayRevenue = weeklyRevenue[yesterdayLabel] ?? 0;
      
      if (yesterdayRevenue > 0) {
        revenueChangePercentage = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      } else if (todayRevenue > 0) {
        revenueChangePercentage = 100; // Tăng 100% nếu hôm qua không có doanh thu
      }

      emit(state.copyWith(
        isLoading: false,
        shopName: shopName,
        isStoreOpen: isStoreOpen,
        maGianHang: maGianHang,
        dailyOverview: DailyOverview(
          revenue: todayRevenue,
          orderCount: todayOrderCount,
          pendingOrderCount: pendingOrderCount,
        ),
        productInfo: ProductInfo(
          totalProducts: totalProducts,
          activeProducts: activeProducts,
          lowStockCount: lowStockProducts.length,
        ),
        weeklyRevenue: weeklyRevenue,
        lowStockProducts: lowStockProducts,
        recentOrders: recentOrders.cast<model.SellerOrderModel>(),
        revenueChangePercentage: revenueChangePercentage,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải dữ liệu: $e',
      ));
    }
  }

  String _getDayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      case DateTime.sunday: return 'CN';
      default: return '';
    }
  }

  /// Toggle trạng thái cửa hàng (mở/đóng)
  Future<void> toggleStoreStatus() async {
    final newStatus = state.isStoreOpen ? 'dong_cua' : 'mo_cua';
    
    // Lưu trạng thái cũ để rollback nếu lỗi
    final oldStatus = state.isStoreOpen;
    
    // Cập nhật UI ngay lập tức để trải nghiệm mượt mà
    emit(state.copyWith(isStoreOpen: !oldStatus));

    try {
      final success = await _shopService.updateShopStatus(newStatus);
      if (success) {
        // Lưu lại trạng thái vào local để persist qua logout
        if (state.maGianHang != null) {
          await _localStorageService.saveShopStatus(state.maGianHang!, newStatus);
        }
        
        try {
          final user = await _authService.getCurrentUser();
          await _localStorageService.saveShopStatus(user.maNguoiDung, newStatus);
          debugPrint('🏪 [HOME_CUBIT] Saved new status to local for user: $newStatus');
        } catch (_) {}
      } else {
        // Rollback nếu API trả về false
        emit(state.copyWith(
          isStoreOpen: oldStatus,
          errorMessage: 'Không thể cập nhật trạng thái gian hàng',
        ));
      }
    } catch (e) {
      // Rollback và báo lỗi nếu có exception
      emit(state.copyWith(
        isStoreOpen: oldStatus,
        errorMessage: 'Lỗi cập nhật trạng thái: $e',
      ));
    }
  }

  /// Refresh dữ liệu
  Future<void> refreshData() async {
    await initializeHome();
  }

  /// Format số tiền thành chuỗi hiển thị
  String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted đ';
  }
}
