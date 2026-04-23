import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_model.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final WalletService _walletService;
  final String walletId;
  String _currentFilter = '';

  WalletCubit({
    required WalletService walletService,
    required this.walletId,
  })  : _walletService = walletService,
        super(WalletInitial());

  Future<void> loadWallet({String? filterType}) async {
    if (walletId.isEmpty) {
      emit(const WalletError('Không tìm thấy thông tin ví của người dùng.'));
      return;
    }

    try {
      if (state is! WalletLoaded) {
        emit(WalletLoading());
      }
      
      _currentFilter = filterType ?? _currentFilter;
      final String? apiFilter = _currentFilter.isEmpty || _currentFilter == 'tat_ca' ? null : _currentFilter;

      final data = await _walletService.getWalletBalance(
        walletId: walletId,
        filterType: apiFilter,
      );

      emit(WalletLoaded(walletData: data, filterType: _currentFilter.isEmpty ? 'tat_ca' : _currentFilter));
    } catch (e) {
      emit(WalletError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> requestWithdrawal(WithdrawRequest request) async {
    try {
      final currentState = state;
      emit(WalletLoading());
      
      await _walletService.requestWithdrawal(
        walletId: walletId,
        request: request,
      );

      emit(const WalletWithdrawSuccess('Yêu cầu rút tiền đã được tạo thành công, đang chờ duyệt.'));
      
      // Tải lại dữ liệu ví sau khi rút tiền thành công
      await loadWallet(filterType: _currentFilter);
    } catch (e) {
      emit(WalletError(e.toString().replaceAll('Exception: ', '')));
      // Cố gắng trở lại trạng thái cũ
      loadWallet(filterType: _currentFilter);
    }
  }
}
