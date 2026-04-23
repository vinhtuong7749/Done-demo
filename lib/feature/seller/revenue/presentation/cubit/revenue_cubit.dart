import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/nhom_nguyen_lieu_service.dart';
import '../../../../../core/services/revenue_service.dart';
import '../../../../../core/services/seller_order_service.dart';
import '../../../../../core/models/seller_order_model.dart' as model;
import 'revenue_state.dart';
import 'package:intl/intl.dart';

class SellerRevenueCubit extends Cubit<SellerRevenueState> {
  final RevenueService _revenueService;
  final SellerOrderService _orderService;

  SellerRevenueCubit({
    RevenueService? revenueService,
    SellerOrderService? orderService,
  })  : _revenueService = revenueService ?? RevenueService(),
        _orderService = orderService ?? SellerOrderService(),
        super(const SellerRevenueState()) {
    loadRevenue();
  }

  Future<void> loadRevenue() async {
    print('📊 [REVENUE_CUBIT] loadRevenue called');
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final now = DateTime.now();
      DateTime fromDate;
      DateTime toDate = now;

      switch (state.selectedDateFilter) {
        case DateFilter.today:
          fromDate = DateTime(now.year, now.month, now.day);
          break;
        case DateFilter.week:
          fromDate = now.subtract(const Duration(days: 7));
          break;
        case DateFilter.month:
          fromDate = DateTime(now.year, now.month, 1);
          break;
        case DateFilter.year:
          fromDate = DateTime(now.year, 1, 1);
          break;
        case DateFilter.custom:
          fromDate = state.customStartDate ?? now.subtract(const Duration(days: 30));
          toDate = state.customEndDate ?? now;
          break;
      }

      final dateFormatter = DateFormat('yyyy-MM-dd');
      
      // 1. Fetch Revenue Data
      final revenueResult = await _revenueService.getRevenue(
        fromDate: dateFormatter.format(fromDate),
        toDate: dateFormatter.format(toDate),
      );
      print('📊 [REVENUE_CUBIT] Revenue Result: $revenueResult');

      // 2. Fetch Orders Data for real stats (with robust error handling)
      List<model.SellerOrderModel> filteredOrders = [];
      try {
        // First, get stall ID to avoid 404 (needs real stall ID)
        String? maGianHang;
        try {
          final prodResponse = await NhomNguyenLieuService.getSellerProducts(limit: 1);
          if (prodResponse.data.isNotEmpty) {
            maGianHang = prodResponse.data[0]['ma_gian_hang'];
            print('📊 [REVENUE_CUBIT] Found stall ID: $maGianHang');
          }
        } catch (e) {
          print('⚠️ [REVENUE_CUBIT] Could not fetch stall ID: $e');
        }

        final ordersResponse = await _orderService.getOrders(
          limit: 100,
          maGianHang: maGianHang,
        );
        final List<model.SellerOrderModel> allOrders = ordersResponse.items;
        
        // Filter orders by date range
        filteredOrders = allOrders.where((order) {
          if (order.thoiGianGiaoHang == null) return false;
          return order.thoiGianGiaoHang!.isAfter(fromDate) && 
                 order.thoiGianGiaoHang!.isBefore(toDate.add(const Duration(days: 1)));
        }).toList();
        print('📊 [REVENUE_CUBIT] Successfully fetched and filtered ${filteredOrders.length} orders');
      } catch (e) {
        print('⚠️ [REVENUE_CUBIT] Warning: Failed to fetch orders for real stats: $e');
        // Proceed with empty orders, but totalRevenue is still valid from revenueResult
      }

      if (revenueResult.containsKey('tong_doanh_thu')) {
        print('📊 [REVENUE_CUBIT] Processing Success Block');
        final totalRevenue = (revenueResult['tong_doanh_thu'] as num).toDouble();
        final details = (revenueResult['chi_tiet'] ?? []) as List<dynamic>;

        final Map<String, double> dailyRevenue = {};
        for (var item in details) {
          final date = item['ngay'] as String;
          final amount = (item['doanh_thu'] as num).toDouble();
          dailyRevenue[date] = amount;
        }

        // Calculate Stats from Orders
        final orderCount = filteredOrders.length;
        final averageOrderValue = orderCount > 0 ? totalRevenue / orderCount : 0.0;
        
        // Step 1: Build product stats from order data
        final Map<String, _ProductStats> productStatsMap = {};
        for (var order in filteredOrders) {
          for (var item in order.chiTietDonHang) {
            final productId = item.maNguyenLieu;
            final stats = productStatsMap.putIfAbsent(productId, () => _ProductStats(
              name: item.tenNguyenLieu,
              totalAmount: 0,
              orderCount: 0,
              imageUrl: null, // Orders API does NOT return images
            ));
            stats.totalAmount += item.thanhTien;
            stats.orderCount += item.soLuong;
          }
        }
        print('📊 [REVENUE] Product stats built: ${productStatsMap.keys.toList()}');

        // Step 2: Fetch catalog images from seller products API
        Map<String, String> catalogImages = {};
        try {
          final prodResponse = await NhomNguyenLieuService.getSellerProducts(limit: 100);
          print('📊 [REVENUE] Catalog fetched: ${prodResponse.data.length} products');
          for (var p in prodResponse.data) {
            final ma = (p['ma_nguyen_lieu'] ?? '').toString();
            final img = (p['hinh_anh'] ?? '').toString();
            if (ma.isNotEmpty && img.isNotEmpty && img != 'null') {
              catalogImages[ma] = img;
            }
          }
          print('📊 [REVENUE] Catalog images mapped: ${catalogImages.length} entries');
        } catch (e) {
          print('⚠️ [REVENUE] Catalog fetch failed: $e');
        }

        // Step 3: Build best selling products with image resolution
        // Priority: catalog image > constructed URL > placeholder
        const imageServerBase = 'http://207.180.233.84/uploads/ingredients';
        
        final bestSellingProducts = productStatsMap.entries.map((e) {
          final productId = e.key;
          String finalImg;
          
          // Try catalog image first
          if (catalogImages.containsKey(productId) && catalogImages[productId]!.isNotEmpty) {
            finalImg = catalogImages[productId]!;
          } else {
            // Construct URL from known pattern: http://207.180.233.84/uploads/ingredients/{id}.jpg
            finalImg = '$imageServerBase/$productId.jpg';
          }
          
          print('📊 [REVENUE] Product "$productId" (${e.value.name}) → image: $finalImg');

          return BestSellingProduct(
            name: e.value.name,
            imageUrl: finalImg,
            orderCount: e.value.orderCount,
            totalAmount: e.value.totalAmount,
            changePercentage: 0,
          );
        }).toList();
        
        bestSellingProducts.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        emit(state.copyWith(
          isLoading: false,
          errorMessage: null,
          paidBalance: totalRevenue,
          dailyRevenue: dailyRevenue,
          bestSellingProducts: bestSellingProducts.take(5).toList(),
          orderCount: orderCount,
          averageOrderValue: averageOrderValue,
          conversionRate: 2.5, // Hardcoded for now
          revenueChangePercentage: 15.0, // Hardcoded for now
        ));
        print('📊 [REVENUE_CUBIT] State Emitted with real stats');
      } else {
        print('📊 [REVENUE_CUBIT] Entering Error Block');
        emit(state.copyWith(
          isLoading: false,
          errorMessage: revenueResult['message'] ?? 'Không thể tải dữ liệu doanh thu',
        ));
      }
    } catch (e) {
      print('📊 [REVENUE_CUBIT] Catch Block Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectBalanceTab(BalanceTab tab) {
    emit(state.copyWith(selectedBalanceTab: tab));
  }

  void selectDateFilter(DateFilter filter) {
    emit(state.copyWith(selectedDateFilter: filter));
    if (filter != DateFilter.custom) {
      loadRevenue();
    }
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    emit(state.copyWith(
      selectedDateFilter: DateFilter.custom,
      customStartDate: start,
      customEndDate: end,
    ));
    loadRevenue();
  }

  void toggleChartType() {
    final newType = state.chartType == ChartType.column ? ChartType.line : ChartType.column;
    emit(state.copyWith(chartType: newType));
  }

  void requestSettlement() {
    // TODO: Implement settlement request
  }
}

class _ProductStats {
  String name;
  double totalAmount;
  int orderCount;
  String? imageUrl;

  _ProductStats({
    required this.name,
    required this.totalAmount,
    required this.orderCount,
    this.imageUrl,
  });
}

