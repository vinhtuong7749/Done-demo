import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/market_manager_service.dart';
import 'seller_management_state.dart';

class SellerManagementCubit extends Cubit<SellerManagementState> {
  final MarketManagerService _service;
  static const int _limit = 10;

  SellerManagementCubit({MarketManagerService? service})
      : _service = service ?? MarketManagerService(),
        super(const SellerManagementState());

  Future<void> loadSellers() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _service.getSellers(page: 1, limit: _limit);

      if (response.success) {
        emit(state.copyWith(
          isLoading: false,
          sellers: response.sellers,
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách tiểu thương',
        ));
      }
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi: ${e.toString()}',
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.getSellers(page: nextPage, limit: _limit);

      if (response.success) {
        final updatedSellers = [...state.sellers, ...response.sellers];
        emit(state.copyWith(
          isLoadingMore: false,
          sellers: updatedSellers,
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ));
      } else {
        emit(state.copyWith(isLoadingMore: false));
      }
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Load more error: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    await loadSellers();
  }

  Future<bool> addSeller({
    required String tenDangNhap,
    required String matKhau,
    required String tenNguoiDung,
    required String sdt,
    required String diaChi,
    required String gioiTinh,
    required String tenGianHang,
    required String viTri,
  }) async {
    try {
      final success = await _service.addSeller(
        tenDangNhap: tenDangNhap,
        matKhau: matKhau,
        tenNguoiDung: tenNguoiDung,
        sdt: sdt,
        diaChi: diaChi,
        gioiTinh: gioiTinh,
        tenGianHang: tenGianHang,
        viTri: viTri,
      );

      if (success) {
        await loadSellers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Add seller error: $e');
      return false;
    }
  }

  Future<void> loadPendingSellers() async {
    emit(state.copyWith(isLoadingPending: true, errorMessage: null));
    try {
      final response = await _service.getPendingSellers(page: 1, limit: 50);
      if (response['success'] == true) {
        emit(state.copyWith(
          isLoadingPending: false,
          pendingSellers: response['data'],
          totalPending: response['meta']['total'],
        ));
      } else {
        emit(state.copyWith(
          isLoadingPending: false,
          errorMessage: 'Không thể tải danh sách chờ',
        ));
      }
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Load pending error: $e');
      emit(state.copyWith(
        isLoadingPending: false,
        errorMessage: 'Lỗi: ${e.toString()}',
      ));
    }
  }

  Future<bool> createStallForPendingSeller({
    required String maNguoiDung,
    required String tenGianHang,
    required String stallLocation,
    required int gridCol,
    required int gridRow,
  }) async {
    try {
      final success = await _service.registerStall(
        maNguoiDung: maNguoiDung,
        tenGianHang: tenGianHang,
        stallLocation: stallLocation,
        gridCol: gridCol,
        gridRow: gridRow,
      );

      if (success) {
        // Refresh both lists
        await loadSellers();
        await loadPendingSellers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Create stall error: $e');
      return false;
    }
  }
}
