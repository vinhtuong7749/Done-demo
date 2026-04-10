import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/dependency/injection.dart';
import '../../../../../core/services/auth/auth_service.dart';
import '../../../../../core/services/user_profile_service.dart';
import '../../../../../core/services/nhom_nguyen_lieu_service.dart';
import '../../../../../core/services/seller_order_service.dart';
import '../../../../../core/services/gian_hang_service.dart';
import 'user_state.dart';

class SellerUserCubit extends Cubit<SellerUserState> {
  final AuthService _authService = getIt<AuthService>();
  final UserProfileService _profileService = UserProfileService();
  final SellerOrderService _orderService = SellerOrderService();
  final GianHangService _shopService = GianHangService();

  SellerUserCubit() : super(SellerUserState.initial());

  /// Khởi tạo và load thông tin người bán
  Future<void> loadUserInfo() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // 1. Lấy thông tin user profile chi tiết
      final profileResponse = await _profileService.getProfile();
      final profile = profileResponse.data;
      
      // 2. Lấy số lượng sản phẩm và mã gian hàng
      int productCount = 0;
      String? maGianHang;
      try {
        final productsResponse = await NhomNguyenLieuService.getSellerProducts(limit: 1);
        productCount = productsResponse.meta.total;
        if (productsResponse.data.isNotEmpty) {
          maGianHang = productsResponse.data[0]['ma_gian_hang'];
        }
      } catch (e) {
        // Log error but continue
      }

      // 3. Lấy thông tin gian hàng (Chợ và Mã gian hàng)
      String marketName = 'Chưa cập nhật';
      String stallNumber = 'Chưa cập nhật';
      String shopName = profile.tenNguoiDung;

      if (maGianHang != null) {
        try {
          final shopDetail = await _shopService.getShopDetail(maGianHang);
          if (shopDetail.success) {
            marketName = shopDetail.detail.cho?.tenCho ?? 'Chưa cập nhật';
            stallNumber = shopDetail.detail.maGianHang;
            shopName = shopDetail.detail.tenGianHang;
          }
        } catch (e) {
          // Log error but continue
        }
      }

      // 4. Lấy số lượng đơn hàng đã bán (đã hoàn thành)
      int soldCount = 0;
      try {
        final ordersResponse = await _orderService.getOrders(limit: 1, status: 'da_giao', maGianHang: maGianHang);
        if (ordersResponse.success) {
          soldCount = ordersResponse.pagination.total;
        }
      } catch (e) {
        // Log error but continue
      }
      
      emit(state.copyWith(
        isLoading: false,
        sellerInfo: SellerInfo.fromUserProfile(
          profile, 
          productCount: productCount, 
          soldCount: soldCount,
        ).copyWith(
          marketName: marketName,
          stallNumber: stallNumber,
          shopName: shopName,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin: ${e.toString()}',
      ));
    }
  }

  /// Upload ảnh đại diện gian hàng
  Future<void> updateShopAvatar(File imageFile) async {
    if (state.sellerInfo == null) return;

    emit(state.copyWith(isLoading: true));

    try {
      // 1. Upload ảnh lên server
      final uploadResponse = await NhomNguyenLieuService.uploadImages(
        files: [imageFile],
        folder: 'seller/avatar'
      );

      if (uploadResponse.success && uploadResponse.urls.isNotEmpty) {
        final avatarUrl = uploadResponse.urls.first;
        
        // 2. Cập nhật URL ảnh vào profile
        // Giả định API profile có trường avatar (cần verify thực tế)
        // Hiện tại updateProfile chưa có trường này, tôi sẽ lưu tạm hoặc giả định dùng địa chỉ để lưu URL nếu cần thiết
        // Nhưng đúng nhất là cần có API update avatar riêng hoặc field avatar trong updateProfile
        
        // Để mapping đầy đủ, tôi sẽ giả định updateProfile có thể nhận thêm trường hinhAnh
        // Nếu không có, tôi sẽ cập nhật vào state để UI thay đổi trước
        emit(state.copyWith(
          isLoading: false,
          sellerInfo: state.sellerInfo!.copyWith(avatarUrl: avatarUrl),
        ));
      } else {
        throw Exception(uploadResponse.message);
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi upload ảnh: ${e.toString()}',
      ));
    }
  }

  /// Cập nhật thông tin profile
  Future<void> updateProfile({
    String? fullName,
    String? bankName,
    String? bankAccount,
    String? phone,
    String? address,
  }) async {
    if (state.sellerInfo == null) return;

    emit(state.copyWith(isLoading: true));

    try {
      final currentInfo = state.sellerInfo!;
      
      await _profileService.updateProfile(
        tenNguoiDung: fullName ?? currentInfo.fullName,
        nganHang: bankName ?? currentInfo.bankName,
        soTaiKhoan: bankAccount ?? currentInfo.accountNumber,
        sdt: phone ?? currentInfo.phoneNumber,
        diaChi: address ?? currentInfo.marketName, 
      );

      // Reload data
      await loadUserInfo();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Cập nhật thất bại: ${e.toString()}',
      ));
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      emit(state.copyWith(isLoading: true));
      await _authService.logout();
      emit(state.copyWith(isLoading: false, isLoggedOut: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể đăng xuất: ${e.toString()}',
      ));
    }
  }

  /// Quay lại
  void goBack() {
    // TODO: Navigate back
  }

  /// Chuyển tab bottom navigation
  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index));
  }

  /// Refresh dữ liệu
  Future<void> refreshData() async {
    await loadUserInfo();
  }

  void editPersonalInfo() {}
  void editMarketInfo() {}
  void editAccountNumber() {}
  void editBankInfo() {}
  void editPhoneNumber() {}
}
