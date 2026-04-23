import 'package:equatable/equatable.dart';
import '../../../../../core/models/seller_list_model.dart';

class SellerManagementState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<SellerInfo> sellers;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  // Pending Sellers
  final bool isLoadingPending;
  final List<dynamic> pendingSellers;
  final int totalPending;

  const SellerManagementState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.sellers = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasMore = true,
    this.isLoadingPending = false,
    this.pendingSellers = const [],
    this.totalPending = 0,
  });

  SellerManagementState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<SellerInfo>? sellers,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? hasMore,
    bool? isLoadingPending,
    List<dynamic>? pendingSellers,
    int? totalPending,
  }) {
    return SellerManagementState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      sellers: sellers ?? this.sellers,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingPending: isLoadingPending ?? this.isLoadingPending,
      pendingSellers: pendingSellers ?? this.pendingSellers,
      totalPending: totalPending ?? this.totalPending,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        errorMessage,
        sellers,
        currentPage,
        totalPages,
        total,
        hasMore,
        isLoadingPending,
        pendingSellers,
        totalPending,
      ];
}
