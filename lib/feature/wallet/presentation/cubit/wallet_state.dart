import 'package:equatable/equatable.dart';
import '../../models/wallet_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletBalanceResponse walletData;
  final String filterType; // 'hom_nay', 'tuan_nay', 'thang_nay', 'tat_ca'
  
  const WalletLoaded({required this.walletData, required this.filterType});

  @override
  List<Object?> get props => [walletData, filterType];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletWithdrawSuccess extends WalletState {
  final String message;

  const WalletWithdrawSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
