import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../models/wallet_model.dart';
import '../../../../core/dependency/injection.dart';

class WalletService {
  final http.Client _client = http.Client();

  Future<WalletBalanceResponse> getWalletBalance({
    required String walletId,
    String? filterType,
    String? fromDate,
    String? toDate,
  }) async {
    final token = await getIt<AuthService>().getToken();
    if (token == null) {
      throw Exception('Không tìm thấy token đăng nhập');
    }

    final queryParameters = <String, String>{};
    if (filterType != null) {
      queryParameters['filter_type'] = filterType;
    }
    if (fromDate != null) {
      queryParameters['from_date'] = fromDate;
    }
    if (toDate != null) {
      queryParameters['to_date'] = toDate;
    }

    // AppConfig.baseUrl contains /api
    final uri = Uri.parse('${AppConfig.baseUrl}/wallets/$walletId/balance')
        .replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WalletBalanceResponse.fromJson(data);
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Lỗi khi tải thông tin ví');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<void> requestWithdrawal({
    required String walletId,
    required WithdrawRequest request,
  }) async {
    final token = await getIt<AuthService>().getToken();
    if (token == null) {
      throw Exception('Không tìm thấy token đăng nhập');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/wallets/$walletId/withdraw');

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return; // Success
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Lỗi khi yêu cầu rút tiền');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }
}
