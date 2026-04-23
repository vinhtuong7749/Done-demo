import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/models/seller_list_model.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/seller_management_cubit.dart';
import '../cubit/seller_management_state.dart';
import '../widget/add_seller_popup.dart';
import '../widget/create_stall_popup.dart';

class SellerManagementScreen extends StatelessWidget {
  const SellerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerManagementCubit()
        ..loadSellers()
        ..loadPendingSellers(),
      child: const SellerManagementView(),
    );
  }
}

class SellerManagementView extends StatefulWidget {
  const SellerManagementView({super.key});

  @override
  State<SellerManagementView> createState() => _SellerManagementViewState();
}

class _SellerManagementViewState extends State<SellerManagementView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SellerManagementCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2F8000),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Quản lý Tiểu thương',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                context.read<SellerManagementCubit>().refresh();
                context.read<SellerManagementCubit>().loadPendingSellers();
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Đang hoạt động'),
              Tab(text: 'Chờ tạo sạp'),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSellerPopup(context),
        backgroundColor: const Color(0xFF2F8000),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Thêm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
        body: TabBarView(
          children: [
            // Tab 1: Đang hoạt động
            BlocBuilder<SellerManagementCubit, SellerManagementState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const BuyerLoading(message: 'Đang tải danh sách...');
                }

                if (state.errorMessage != null) {
                  return _buildErrorView(context, state.errorMessage!);
                }

                return _buildSellerList(context, state);
              },
            ),

            // Tab 2: Chờ tạo sạp
            BlocBuilder<SellerManagementCubit, SellerManagementState>(
              builder: (context, state) {
                if (state.isLoadingPending) {
                  return const BuyerLoading(message: 'Đang tải danh sách chờ...');
                }
                
                if (state.pendingSellers.isEmpty) {
                  return const Center(child: Text('Không có tiểu thương chờ tạo sạp'));
                }

                return _buildPendingList(context, state);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSellerPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SellerManagementCubit>(),
        child: const AddSellerPopup(),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<SellerManagementCubit>().loadSellers(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerList(BuildContext context, SellerManagementState state) {
    return Column(
      children: [
        _buildHeader(state),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<SellerManagementCubit>().refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.sellers.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.sellers.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildSellerCard(state.sellers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingList(BuildContext context, SellerManagementState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng: ${state.totalPending} chờ duyệt',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<SellerManagementCubit>().loadPendingSellers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.pendingSellers.length,
              itemBuilder: (context, index) {
                final pending = state.pendingSellers[index];
                return _buildPendingCard(context, pending);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(BuildContext context, dynamic pending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending['ten_nguoi_dung'] ?? 'Không rõ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pending['ma_nguoi_dung'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showCreateStallPopup(context, pending),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F8000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tạo sạp'),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (pending['sdt'] != null && pending['sdt'].toString().isNotEmpty)
            _buildInfoRow(Icons.phone, pending['sdt']),
          if (pending['dia_chi'] != null && pending['dia_chi'].toString().isNotEmpty)
            _buildInfoRow(Icons.location_on, pending['dia_chi']),
        ],
      ),
    );
  }

  void _showCreateStallPopup(BuildContext context, dynamic pending) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SellerManagementCubit>(),
        child: CreateStallPopup(
          maNguoiDung: pending['ma_nguoi_dung'],
          tenNguoiDung: pending['ten_nguoi_dung'] ?? '',
        ),
      ),
    );
  }

  Widget _buildHeader(SellerManagementState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng: ${state.total} tiểu thương',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            'Trang ${state.currentPage}/${state.totalPages}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(SellerInfo seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F8000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2F8000),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.tenNguoiDung,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seller.maNguoiDung,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(seller.isActive),
            ],
          ),
          const SizedBox(height: 12),
          if (seller.sdt != null && seller.sdt!.isNotEmpty)
            _buildInfoRow(Icons.phone, seller.sdt!),
          if (seller.diaChi != null && seller.diaChi!.isNotEmpty)
            _buildInfoRow(Icons.location_on, seller.diaChi!),
          if (seller.gianHang.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Gian hàng (${seller.gianHang.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            ...seller.gianHang.map((stall) => _buildStallItem(stall)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Tạm khóa',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF4CAF50) : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B6B6B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B6B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStallItem(SellerStallInfo stall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: stall.hasPosition
                  ? const Color(0xFF4CAF50)
                  : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stall.tenGianHang,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (stall.viTri != null)
                  Text(
                    stall.viTri!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
              ],
            ),
          ),
          if (stall.hasPosition)
            Text(
              '(${stall.gridRow}, ${stall.gridCol})',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
