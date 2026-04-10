import 'package:equatable/equatable.dart';
import '../../../../../core/models/user_model.dart';
import '../../../../../core/services/user_profile_service.dart';

/// Model đại diện cho thông tin người bán
class SellerInfo extends Equatable {
  final String id;
  final String fullName;
  final String shopName;
  final String phoneNumber;
  final String bankName;
  final String accountNumber;
  final String marketName;
  final String stallNumber;
  final List<String> categories;
  final String avatarUrl;
  final double rating;
  final int productCount;
  final int soldCount;
  
  String get categoriesDisplay => categories.join(', ');

  const SellerInfo({
    required this.id,
    required this.fullName,
    required this.shopName,
    required this.phoneNumber,
    required this.bankName,
    required this.accountNumber,
    required this.marketName,
    required this.stallNumber,
    required this.categories,
    required this.avatarUrl,
    this.rating = 5.0,
    this.productCount = 0,
    this.soldCount = 0,
  });

  factory SellerInfo.fromUserProfile(UserProfileData profile, {int productCount = 0, int soldCount = 0}) {
    return SellerInfo(
      id: profile.maNguoiDung,
      fullName: profile.tenNguoiDung,
      shopName: profile.tenNguoiDung, // Giả định tên người dùng là tên shop
      phoneNumber: profile.sdt ?? 'Chưa cập nhật',
      bankName: profile.nganHang ?? 'Chưa cập nhật',
      accountNumber: profile.soTaiKhoan ?? 'Chưa cập nhật',
      marketName: 'Chưa cập nhật',
      stallNumber: 'Chưa cập nhật',
      categories: const ['Gia vị', 'Thịt heo'],
      avatarUrl: 'assets/img/seller_home_avatar.png',
      rating: 5.0,
      productCount: productCount,
      soldCount: soldCount,
    );
  }

  SellerInfo copyWith({
    String? id,
    String? fullName,
    String? shopName,
    String? phoneNumber,
    String? bankName,
    String? accountNumber,
    String? marketName,
    String? stallNumber,
    List<String>? categories,
    String? avatarUrl,
    double? rating,
    int? productCount,
    int? soldCount,
  }) {
    return SellerInfo(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      shopName: shopName ?? this.shopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      marketName: marketName ?? this.marketName,
      stallNumber: stallNumber ?? this.stallNumber,
      categories: categories ?? this.categories,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      productCount: productCount ?? this.productCount,
      soldCount: soldCount ?? this.soldCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        shopName,
        phoneNumber,
        bankName,
        accountNumber,
        marketName,
        stallNumber,
        categories,
        avatarUrl,
        rating,
        productCount,
        soldCount,
      ];
}

/// State chính của Seller User
class SellerUserState extends Equatable {
  final bool isLoading;
  final bool isLoggedOut;
  final String? errorMessage;
  final SellerInfo? sellerInfo;
  final int currentTabIndex;

  const SellerUserState({
    this.isLoading = false,
    this.isLoggedOut = false,
    this.errorMessage,
    this.sellerInfo,
    this.currentTabIndex = 4, // Tab Tài khoản mặc định
  });

  /// Factory tạo state ban đầu
  factory SellerUserState.initial() {
    return const SellerUserState(isLoading: true, isLoggedOut: false);
  }

  SellerUserState copyWith({
    bool? isLoading,
    bool? isLoggedOut,
    String? errorMessage,
    SellerInfo? sellerInfo,
    int? currentTabIndex,
  }) {
    return SellerUserState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      errorMessage: errorMessage,
      sellerInfo: sellerInfo ?? this.sellerInfo,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoggedOut,
        errorMessage,
        sellerInfo,
        currentTabIndex,
      ];
}
