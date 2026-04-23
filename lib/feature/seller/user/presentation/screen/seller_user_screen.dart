import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../../../../../core/config/route_name.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';
import '../../../../wallet/presentation/screens/wallet_screen.dart';

class SellerUserScreen extends StatelessWidget {
  const SellerUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerUserCubit()..loadUserInfo(),
      child: const _SellerUserView(),
    );
  }
}

class _SellerUserView extends StatelessWidget {
  const _SellerUserView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocConsumer<SellerUserCubit, SellerUserState>(
        listener: (context, state) {
          if (state.isLoggedOut) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              RouteName.login,
              (route) => false,
            );
          }
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.sellerInfo == null) {
            return const BuyerLoading(message: 'Đang tải thông tin...');
          }

          final info = state.sellerInfo;
          if (info == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => context.read<SellerUserCubit>().refreshData(),
                color: const Color(0xFF2E7D32),
                child: CustomScrollView(
                  slivers: [
                    // Hero Header
                    SliverToBoxAdapter(child: _buildHeroHeader(context, info, state)),
                    // Stats Row
                    SliverToBoxAdapter(child: _buildStatsRow(context, info)),
                    // Info Cards
                    SliverToBoxAdapter(child: _buildPersonalInfo(context, info)),
                    SliverToBoxAdapter(child: _buildBankInfo(context, info)),
                    SliverToBoxAdapter(child: _buildAccountActions(context, info)),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
              if (state.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, SellerInfo info, SellerUserState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gian hàng của tôi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_rounded, color: Colors.white70, size: 26),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Avatar + Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showImageSourceDialog(context),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: info.avatarUrl.startsWith('http')
                                ? Image.network(
                                    info.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                                  )
                                : _buildAvatarPlaceholder(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _showImageSourceDialog(context),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF26CD3A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.shopName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${info.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Uy tín',
                                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.marketName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Performance banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: Color(0xFF69F0AE), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đã bán hơn ${info.soldCount} đơn hàng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white60),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFF388E3C),
      child: const Icon(Icons.store_rounded, color: Colors.white, size: 44),
    );
  }

  Widget _buildStatsRow(BuildContext context, SellerInfo info) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: '${info.productCount}',
            label: 'Sản phẩm',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF2E7D32),
          ),
          _buildDivider(),
          _buildStatItem(
            value: '${info.soldCount}',
            label: 'Đơn đã bán',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF1565C0),
          ),
          _buildDivider(),
          _buildStatItem(
            value: '${info.rating.toStringAsFixed(1)}⭐',
            label: 'Đánh giá',
            icon: Icons.star_rounded,
            color: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 44, color: const Color(0xFFE5E7EB));
  }

  Widget _buildPersonalInfo(BuildContext context, SellerInfo info) {
    return _buildSectionCard(
      title: 'Thông tin cá nhân',
      icon: Icons.person_rounded,
      iconColor: const Color(0xFF2E7D32),
      children: [
        _buildInfoTile(
          context,
          icon: Icons.badge_rounded,
          iconColor: const Color(0xFF2E7D32),
          label: 'Họ và tên',
          value: info.fullName,
          onEdit: () => _showEditDialog(context, 'Họ và tên', info.fullName, (val) {
            context.read<SellerUserCubit>().updateProfile(fullName: val);
          }),
        ),
        _buildDividerLine(),
        _buildInfoTile(
          context,
          icon: Icons.storefront_rounded,
          iconColor: const Color(0xFF1565C0),
          label: 'Chợ',
          value: info.marketName,
        ),
        _buildDividerLine(),
        _buildInfoTile(
          context,
          icon: Icons.tag_rounded,
          iconColor: const Color(0xFF6A1B9A),
          label: 'Mã gian hàng',
          value: info.stallNumber,
        ),
        _buildDividerLine(),
        _buildInfoTile(
          context,
          icon: Icons.phone_rounded,
          iconColor: const Color(0xFFE65100),
          label: 'Điện thoại',
          value: info.phoneNumber,
          onEdit: () => _showEditDialog(context, 'Số điện thoại', info.phoneNumber, (val) {
            context.read<SellerUserCubit>().updateProfile(phone: val);
          }),
        ),
      ],
    );
  }

  Widget _buildBankInfo(BuildContext context, SellerInfo info) {
    return _buildSectionCard(
      title: 'Thông tin ngân hàng',
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFF1565C0),
      children: [
        _buildInfoTile(
          context,
          icon: Icons.credit_card_rounded,
          iconColor: const Color(0xFF1565C0),
          label: 'Số tài khoản',
          value: info.accountNumber,
          onEdit: () => _showEditDialog(context, 'Số tài khoản', info.accountNumber, (val) {
            context.read<SellerUserCubit>().updateProfile(bankAccount: val);
          }),
        ),
        _buildDividerLine(),
        _buildInfoTile(
          context,
          icon: Icons.account_balance_rounded,
          iconColor: const Color(0xFF1565C0),
          label: 'Ngân hàng',
          value: info.bankName,
          onEdit: () => _showEditDialog(context, 'Ngân hàng', info.bankName, (val) {
            context.read<SellerUserCubit>().updateProfile(bankName: val);
          }),
        ),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context, SellerInfo info) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Ví doanh thu',
            onTap: () {
              if (info.walletId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalletScreen(
                      walletId: info.walletId!,
                      userRole: 'nguoi_ban',
                      defaultBankAccount: info.accountNumber != 'Chưa cập nhật' ? info.accountNumber : null,
                      defaultBankName: info.bankName != 'Chưa cập nhật' ? info.bankName : null,
                      defaultAccountName: info.fullName.toUpperCase(),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chưa có thông tin ví doanh thu')),
                );
              }
            },
          ),
          _buildDividerLine(),
          _buildActionTile(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFF6A1B9A),
            label: 'Đổi mật khẩu',
            onTap: () {},
          ),
          _buildDividerLine(),
          _buildActionTile(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF0277BD),
            label: 'Hỗ trợ & Trợ giúp',
            onTap: () {},
          ),
          _buildDividerLine(),
          _buildActionTile(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFC62828),
            label: 'Đăng xuất',
            textColor: const Color(0xFFC62828),
            onTap: () => _showLogoutConfirm(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty || value == 'Chưa cập nhật' ? 'Chưa cập nhật' : value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value.isEmpty || value == 'Chưa cập nhật'
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6B7280)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color textColor = const Color(0xFF1F2937),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textColor == const Color(0xFF1F2937)
                  ? const Color(0xFFD1D5DB)
                  : textColor.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerLine() {
    return const Divider(height: 1, indent: 66, color: Color(0xFFF3F4F6));
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(
      text: (initialValue.isEmpty || initialValue == 'Chưa cập nhật') ? '' : initialValue,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Chỉnh sửa $title',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập $title mới',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerUserCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đổi ảnh đại diện',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2E7D32)),
                ),
                title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1565C0)),
                ),
                title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null && context.mounted) {
      context.read<SellerUserCubit>().updateShopAvatar(File(pickedFile.path));
    }
  }
}
