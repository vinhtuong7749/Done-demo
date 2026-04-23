import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

/// State cho User/Account Screen
class UserState extends Equatable {
  final UserModel? user;
  final String userName;
  final String userImage;
  final int pendingOrders;
  final int processingOrders;
  final int shippingOrders;
  final int completedOrders;
  final bool isLoading;
  final String? errorMessage;
  final bool requiresLogin;
  final int selectedBottomNavIndex;

  const UserState({
    this.user,
    this.userName = '',
    this.userImage = '',
    this.pendingOrders = 0,
    this.processingOrders = 0,
    this.shippingOrders = 0,
    this.completedOrders = 0,
    this.isLoading = false,
    this.errorMessage,
    this.requiresLogin = false,
    this.selectedBottomNavIndex = 4, // 4 = Tài khoản tab
  });

  UserState copyWith({
    UserModel? user,
    String? userName,
    String? userImage,
    int? pendingOrders,
    int? processingOrders,
    int? shippingOrders,
    int? completedOrders,
    bool? isLoading,
    String? errorMessage,
    bool? requiresLogin,
    int? selectedBottomNavIndex,
  }) {
    return UserState(
      user: user ?? this.user,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      processingOrders: processingOrders ?? this.processingOrders,
      shippingOrders: shippingOrders ?? this.shippingOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      requiresLogin: requiresLogin ?? this.requiresLogin,
      selectedBottomNavIndex: selectedBottomNavIndex ?? this.selectedBottomNavIndex,
    );
  }

  @override
  List<Object?> get props => [
        user,
        userName,
        userImage,
        pendingOrders,
        processingOrders,
        shippingOrders,
        completedOrders,
        isLoading,
        errorMessage,
        requiresLogin,
        selectedBottomNavIndex,
      ];
}
