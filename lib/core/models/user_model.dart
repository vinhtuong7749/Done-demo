/// Model cho thông tin người dùng
class UserModel {
  final String maNguoiDung;
  final String tenDangNhap;
  final String tenNguoiDung;
  final String vaiTro;
  final String? gioiTinh;
  final String? sdt;
  final String? diaChi;
  final String? walletId;
  final int approvalStatus;
  final String? stallId;

  UserModel({
    required this.maNguoiDung,
    required this.tenDangNhap,
    required this.tenNguoiDung,
    required this.vaiTro,
    this.gioiTinh,
    this.sdt,
    this.diaChi,
    this.walletId,
    this.approvalStatus = 0,
    this.stallId,
  });

  /// Tạo UserModel từ JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      maNguoiDung: (json['ma_nguoi_dung'] ?? json['user_id']) as String? ?? '',
      tenDangNhap: (json['ten_dang_nhap'] ?? json['login_name']) as String? ?? '',
      tenNguoiDung: (json['ten_nguoi_dung'] ?? json['user_name']) as String? ?? '',
      vaiTro: (json['vai_tro'] ?? json['role']) as String? ?? 'nguoi_mua',
      gioiTinh: (json['gioi_tinh'] ?? json['gender']) as String?,
      sdt: (json['sdt'] ?? json['phone']) as String?,
      diaChi: (json['dia_chi'] ?? json['address']) as String?,
      walletId: json['wallet_id'] as String?,
      approvalStatus: (json['approval_status'] ?? json['trang_thai_duyet']) as int? ?? 0,
      stallId: (json['stall_id'] ?? json['ma_gian_hang']) as String?,
    );
  }

  /// Chuyển UserModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'ma_nguoi_dung': maNguoiDung,
      'ten_dang_nhap': tenDangNhap,
      'ten_nguoi_dung': tenNguoiDung,
      'vai_tro': vaiTro,
      if (gioiTinh != null) 'gioi_tinh': gioiTinh,
      if (sdt != null) 'sdt': sdt,
      if (diaChi != null) 'dia_chi': diaChi,
      if (walletId != null) 'wallet_id': walletId,
      'approval_status': approvalStatus,
      if (stallId != null) 'stall_id': stallId,
    };
  }

  /// Copy với các giá trị mới
  UserModel copyWith({
    String? maNguoiDung,
    String? tenDangNhap,
    String? tenNguoiDung,
    String? vaiTro,
    String? gioiTinh,
    String? sdt,
    String? diaChi,
    String? walletId,
    int? approvalStatus,
    String? stallId,
  }) {
    return UserModel(
      maNguoiDung: maNguoiDung ?? this.maNguoiDung,
      tenDangNhap: tenDangNhap ?? this.tenDangNhap,
      tenNguoiDung: tenNguoiDung ?? this.tenNguoiDung,
      vaiTro: vaiTro ?? this.vaiTro,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      sdt: sdt ?? this.sdt,
      diaChi: diaChi ?? this.diaChi,
      walletId: walletId ?? this.walletId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      stallId: stallId ?? this.stallId,
    );
  }

  /// Getters tiện ích
  bool get isNguoiMua => vaiTro == 'nguoi_mua';
  bool get isNguoiBan => vaiTro == 'nguoi_ban';
  bool get isAdmin => vaiTro == 'admin';
  
  /// Lấy tên hiển thị (ưu tiên tenNguoiDung, fallback tenDangNhap)
  String get displayName => tenNguoiDung.isNotEmpty ? tenNguoiDung : tenDangNhap;

  @override
  String toString() {
    return 'UserModel(maNguoiDung: $maNguoiDung, tenDangNhap: $tenDangNhap, tenNguoiDung: $tenNguoiDung, vaiTro: $vaiTro)';
  }
}
