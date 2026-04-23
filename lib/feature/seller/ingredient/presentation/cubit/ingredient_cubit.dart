import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/nhom_nguyen_lieu_service.dart';
import 'ingredient_state.dart';

class SellerIngredientCubit extends Cubit<SellerIngredientState> {
  SellerIngredientCubit() : super(SellerIngredientState.initial());

  /// Khởi tạo và load danh sách nguyên liệu từ API
  Future<void> loadIngredients({int page = 1}) async {
    emit(state.copyWith(isLoading: true));

    try {
      final response = await NhomNguyenLieuService.getSellerProducts(
        page: page,
        limit: 12, // Khôi phục về 12 vì backend không hỗ trợ limit lớn
        sort: 'ngay_cap_nhat',
        order: 'desc',
      );

      debugPrint('[SELLER_CUBIT] Loaded ${response.data.length} products');

      final ingredients = response.data
          .map((json) => SellerIngredient.fromJson(json))
          .toList();

      emit(state.copyWith(
        isLoading: false,
        ingredients: ingredients,
        currentPage: response.meta.page,
        totalItems: response.meta.total,
        hasNextPage: response.meta.hasNext,
      ));
    } catch (e) {
      debugPrint('[SELLER_CUBIT] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách sản phẩm: ${e.toString()}',
      ));
    }
  }

  /// Cập nhật search query
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Thực hiện tìm kiếm
  void performSearch() {
    // Đã filter tự động qua getter filteredIngredients
    // Có thể thêm logic gọi API search ở đây nếu cần
  }

  /// Chuyển tab bottom navigation
  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index));
  }

  /// Điều hướng đến trang thêm sản phẩm
  void navigateToAddIngredient() {
    // TODO: Implement navigation
  }

  /// Điều hướng đến trang chỉnh sửa sản phẩm
  void navigateToEditIngredient(SellerIngredient ingredient) {
    // TODO: Implement navigation
  }

  /// Xóa sản phẩm
  Future<bool> deleteIngredient(String id) async {
    debugPrint('[SELLER_CUBIT] Deleting product: $id');
    
    try {
      final response = await NhomNguyenLieuService.deleteProduct(id);
      
      if (response.success) {
        debugPrint('[SELLER_CUBIT] ✅ Delete success');
        // Xóa khỏi danh sách local
        final updatedList = state.ingredients.where((item) => item.id != id).toList();
        emit(state.copyWith(ingredients: updatedList));
        return true;
      } else {
        debugPrint('[SELLER_CUBIT] ❌ Delete failed: ${response.message}');
        emit(state.copyWith(
          errorMessage: response.message ?? 'Không thể xóa sản phẩm',
        ));
        return false;
      }
    } catch (e) {
      debugPrint('[SELLER_CUBIT] ❌ Delete exception: $e');
      emit(state.copyWith(
        errorMessage: 'Không thể xóa sản phẩm: ${e.toString()}',
      ));
      return false;
    }
  }
  
  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Quay lại trang trước
  void goBack() {
    // TODO: Implement navigation back
  }

  /// Refresh dữ liệu
  Future<void> refreshData() async {
    await loadIngredients();
  }
}
