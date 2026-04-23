class WalletDetailItem {
  final String loai;
  final String huong; // 'vao' | 'ra'
  final int soTien;
  final String? orderId;
  final String? paymentId;
  final String? feeId;
  final String? cancelReason;
  final String? detailStatus;
  final DateTime? ngay;

  WalletDetailItem({
    required this.loai,
    required this.huong,
    required this.soTien,
    this.orderId,
    this.paymentId,
    this.feeId,
    this.cancelReason,
    this.detailStatus,
    this.ngay,
  });

  factory WalletDetailItem.fromJson(Map<String, dynamic> json) {
    return WalletDetailItem(
      loai: json['loai'] as String? ?? '',
      huong: json['huong'] as String? ?? 'vao',
      soTien: json['so_tien'] as int? ?? 0,
      orderId: json['order_id'] as String?,
      paymentId: json['payment_id'] as String?,
      feeId: json['fee_id'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      detailStatus: json['detail_status'] as String?,
      ngay: json['ngay'] != null ? DateTime.tryParse(json['ngay']) : null,
    );
  }
}

class WalletBalanceResponse {
  final String walletId;
  final String ownerId;
  final String ownerType;
  final DateTime? updatedWallet;
  final int tongTienVao;
  final int tongTienRa;
  final int soDu;
  final int tienDangChoRut;
  final int soDuKhaDung;
  final List<WalletDetailItem> chiTiet;

  WalletBalanceResponse({
    required this.walletId,
    required this.ownerId,
    required this.ownerType,
    this.updatedWallet,
    required this.tongTienVao,
    required this.tongTienRa,
    required this.soDu,
    required this.tienDangChoRut,
    required this.soDuKhaDung,
    required this.chiTiet,
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResponse(
      walletId: json['wallet_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      ownerType: json['owner_type'] as String? ?? '',
      updatedWallet: json['updated_wallet'] != null ? DateTime.tryParse(json['updated_wallet']) : null,
      tongTienVao: json['tong_tien_vao'] as int? ?? 0,
      tongTienRa: json['tong_tien_ra'] as int? ?? 0,
      soDu: json['so_du'] as int? ?? 0,
      tienDangChoRut: json['tien_dang_cho_rut'] as int? ?? 0,
      soDuKhaDung: json['so_du_kha_dung'] as int? ?? 0,
      chiTiet: (json['chi_tiet'] as List<dynamic>?)
              ?.map((e) => WalletDetailItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WithdrawRequest {
  final int amount;
  final String bankBin;
  final String bankAccountNo;
  final String accountName;

  WithdrawRequest({
    required this.amount,
    required this.bankBin,
    required this.bankAccountNo,
    required this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'bank_bin': bankBin,
      'bank_account_no': bankAccountNo,
      'account_name': accountName,
    };
  }
}
