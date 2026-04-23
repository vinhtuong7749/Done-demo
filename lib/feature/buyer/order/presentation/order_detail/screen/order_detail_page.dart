import 'package:dngo/core/widgets/buyer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cubit/order_detail_cubit.dart';
import '../../../../../../core/config/route_name.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/services/order_service.dart';
import '../../../../../../core/services/review_api_service.dart';
import '../widgets/refund_dialog.dart';


/// Màn hình chi tiết đơn hàng
/// 
/// Chức năng:
/// - Hiển thị chi tiết đơn hàng
/// - Hiển thị trạng thái đơn hàng
/// - Hiển thị thông tin giao hàng
/// - Hủy đơn hàng
/// - Đặt lại đơn hàng
/// - Đánh giá đơn hàng
class OrderDetailPage extends StatelessWidget {
  final String? orderId;

  const OrderDetailPage({
    super.key,
    this.orderId,
  });

  static const String routeName = '/order-detail';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderDetailCubit()..loadOrderDetail(orderId ?? 'ORD001'),
      child: const OrderDetailView(),
    );
  }
}

/// View của màn hình chi tiết đơn hàng
class OrderDetailView extends StatefulWidget {
  const OrderDetailView({super.key});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  // Review state for order
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _quickTags = ['Tươi mới', 'Thơm ngon', 'Sạch sẽ'];
  final Set<String> _selectedTags = {};
  
  // Review state for items
  final Map<String, int> _itemRatings = {};
  final Map<String, TextEditingController> _itemReviewControllers = {};
  final Map<String, Set<String>> _itemSelectedTags = {};
  final Set<String> _submittedItemReviews = {}; // Track đã gửi đánh giá
  
  // Loading state
  bool _isSubmittingReview = false;
  final Map<String, bool> _isSubmittingItemReview = {};
  
  // Review API Service
  final ReviewApiService _reviewApiService = ReviewApiService();

  @override
  void dispose() {
    _reviewController.dispose();
    for (var controller in _itemReviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  /// Gửi đánh giá cho một sản phẩm
  Future<void> _submitItemReview({
    required String maDonHang,
    required String maNguyenLieu,
    required String maGianHang,
    required String itemId,
    required String tenNguyenLieu,
  }) async {
    debugPrint('🔵 [REVIEW DEBUG] ========== START SUBMIT ITEM REVIEW ==========');
    debugPrint('🔵 [REVIEW DEBUG] maDonHang: $maDonHang');
    debugPrint('🔵 [REVIEW DEBUG] maNguyenLieu: $maNguyenLieu');
    debugPrint('🔵 [REVIEW DEBUG] maGianHang: $maGianHang');
    debugPrint('🔵 [REVIEW DEBUG] itemId: $itemId');
    debugPrint('🔵 [REVIEW DEBUG] tenNguyenLieu: $tenNguyenLieu');
    
    final rating = _itemRatings[itemId] ?? 0;
    debugPrint('🔵 [REVIEW DEBUG] rating: $rating');
    
    if (rating == 0) {
      debugPrint('⚠️ [REVIEW DEBUG] Rating is 0, showing warning');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmittingItemReview[itemId] = true;
    });
    
    try {
      // Ghép comment từ text field và tags
      final tags = _itemSelectedTags[itemId]?.join(', ') ?? '';
      final comment = _itemReviewControllers[itemId]?.text ?? '';
      final binhLuan = [tags, comment].where((s) => s.isNotEmpty).join('. ');
      
      debugPrint('🔵 [REVIEW DEBUG] tags: $tags');
      debugPrint('🔵 [REVIEW DEBUG] comment: $comment');
      debugPrint('🔵 [REVIEW DEBUG] binhLuan: $binhLuan');
      debugPrint('🔵 [REVIEW DEBUG] Calling ReviewApiService.submitReview...');
      
      final response = await _reviewApiService.submitReview(
        maDonHang: maDonHang,
        maNguyenLieu: maNguyenLieu,
        maGianHang: maGianHang,
        rating: rating,
        binhLuan: binhLuan.isNotEmpty ? binhLuan : 'Đánh giá $rating sao',
      );
      
      debugPrint('✅ [REVIEW DEBUG] Response success: ${response.success}');
      debugPrint('✅ [REVIEW DEBUG] Response danhGiaTb: ${response.danhGiaTb}');
      debugPrint('✅ [REVIEW DEBUG] Response message: ${response.message}');
      
      if (response.success && mounted) {
        setState(() {
          _submittedItemReviews.add(itemId);
        });
        
        _showThankYouDialog(tenNguyenLieu, response.danhGiaTb);
      }
    } on ReviewException catch (e) {
      debugPrint('❌ [REVIEW DEBUG] ReviewException: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: e.statusCode == 403 ? Colors.orange : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [REVIEW DEBUG] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi đánh giá: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('🔵 [REVIEW DEBUG] ========== END SUBMIT ITEM REVIEW ==========');
      if (mounted) {
        setState(() {
          _isSubmittingItemReview[itemId] = false;
        });
      }
    }
  }
  
  /// Gửi đánh giá chung (cho đơn hàng 1 mặt hàng)
  Future<void> _submitOrderReview({
    required String maDonHang,
    required String maNguyenLieu,
    required String maGianHang,
    required String tenNguyenLieu,
  }) async {
    debugPrint('🟢 [REVIEW DEBUG] ========== START SUBMIT ORDER REVIEW ==========');
    debugPrint('🟢 [REVIEW DEBUG] maDonHang: $maDonHang');
    debugPrint('🟢 [REVIEW DEBUG] maNguyenLieu: $maNguyenLieu');
    debugPrint('🟢 [REVIEW DEBUG] maGianHang: $maGianHang');
    debugPrint('🟢 [REVIEW DEBUG] tenNguyenLieu: $tenNguyenLieu');
    debugPrint('🟢 [REVIEW DEBUG] selectedRating: $_selectedRating');
    
    if (_selectedRating == 0) {
      debugPrint('⚠️ [REVIEW DEBUG] Rating is 0, showing warning');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmittingReview = true;
    });
    
    try {
      // Ghép comment từ text field và tags
      final tags = _selectedTags.join(', ');
      final comment = _reviewController.text;
      final binhLuan = [tags, comment].where((s) => s.isNotEmpty).join('. ');
      
      debugPrint('🟢 [REVIEW DEBUG] tags: $tags');
      debugPrint('🟢 [REVIEW DEBUG] comment: $comment');
      debugPrint('🟢 [REVIEW DEBUG] binhLuan: $binhLuan');
      debugPrint('🟢 [REVIEW DEBUG] Calling ReviewApiService.submitReview...');
      
      final response = await _reviewApiService.submitReview(
        maDonHang: maDonHang,
        maNguyenLieu: maNguyenLieu,
        maGianHang: maGianHang,
        rating: _selectedRating,
        binhLuan: binhLuan.isNotEmpty ? binhLuan : 'Đánh giá $_selectedRating sao',
      );
      
      debugPrint('✅ [REVIEW DEBUG] Response success: ${response.success}');
      debugPrint('✅ [REVIEW DEBUG] Response danhGiaTb: ${response.danhGiaTb}');
      debugPrint('✅ [REVIEW DEBUG] Response message: ${response.message}');
      
      if (response.success && mounted) {
        _showThankYouDialog(tenNguyenLieu, response.danhGiaTb);
        
        // Reset form
        setState(() {
          _selectedRating = 0;
          _selectedTags.clear();
          _reviewController.clear();
        });
      }
    } on ReviewException catch (e) {
      debugPrint('❌ [REVIEW DEBUG] ReviewException: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: e.statusCode == 403 ? Colors.orange : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [REVIEW DEBUG] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi đánh giá: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('🟢 [REVIEW DEBUG] ========== END SUBMIT ORDER REVIEW ==========');
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }
  
  /// Hiển thị dialog hoàn tiền
  void _showRefundDialog(OrderDetailData orderDetail) {
    // Chỉ chọn các sản phẩm chưa từng yêu cầu hoàn tiền
    final eligibleItems = orderDetail.items.where((item) => !['cho_duyet', 'da_duyet', 'hoan_hang', 'tu_choi'].contains(item.detailStatus)).toList();
    if (eligibleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có sản phẩm nào có thể hoàn tiền trong đơn hàng này')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => RefundDialog(
        orderId: orderDetail.maDonHang,
        eligibleItems: eligibleItems,
        onConfirm: (refundItems) {
          // Sử dụng context của OrderDetailView thay vì dialogContext
          context.read<OrderDetailCubit>().requestRefund(orderDetail.maDonHang, refundItems);
        },
      ),
    );
  }

  /// Hiển thị dialog cảm ơn
  void _showThankYouDialog(String tenNguyenLieu, double? danhGiaTb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00B40F),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cảm ơn bạn đã đánh giá!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF202020),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đánh giá của bạn cho "$tenNguyenLieu" đã được ghi nhận.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            if (danhGiaTb != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB800), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Đánh giá TB: ${danhGiaTb.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF202020),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B40F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderDetailCubit, OrderDetailState>(
      listener: (context, state) {
        if (state is OrderDetailCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is OrderDetailReordered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to new order or cart
        } else if (state is OrderDetailRefundSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is OrderDetailFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
                  builder: (context, state) {
                    if (state is OrderDetailLoading) {
                      return const BuyerLoading(
              message: 'Đang tải chi tiết đơn hàng...',
            );
                    }

                    if (state is OrderDetailLoaded) {
                      return _buildContent(context, state);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              
              
            ],
          ),
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Background image
        
        // Content
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [

              // Title row with back button
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/img/back.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  const Text(
                    'Chi tiết đơn hàng',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.1,
                      color: Color(0xFF000000),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RouteName.chat),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Color(0xFF00B40F),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Order ID row
              BlocBuilder<OrderDetailCubit, OrderDetailState>(
                builder: (context, state) {
                  if (state is OrderDetailLoaded) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mã đơn hàng:   ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            height: 1.29,
                            color: Color(0xFF000000),
                          ),
                        ),
                        Text(
                          state.orderDetail.maDonHang,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            height: 1.29,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Content
  Widget _buildContent(BuildContext context, OrderDetailLoaded state) {
    final orderDetail = state.orderDetail;
    debugPrint('REFUND DEBUG: tinhTrangDonHang = ${orderDetail.tinhTrangDonHang}');
    for (var item in orderDetail.items) {
      debugPrint('REFUND DEBUG: item detailStatus = ${item.detailStatus}');
    }
    final conditionMet = (orderDetail.tinhTrangDonHang == 'da_giao' || orderDetail.tinhTrangDonHang == 'hoan_thanh') &&
              orderDetail.items.any((item) => !['cho_duyet', 'da_duyet', 'hoan_hang', 'tu_choi'].contains(item.detailStatus));
    debugPrint('REFUND DEBUG: conditionMet = $conditionMet');
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Timeline tracking section
          _buildOrderTimelineSection(orderDetail.tinhTrangDonHang),
          
          const SizedBox(height: 16),
          
          // Delivery info section
          _buildDeliveryInfoSection(orderDetail),
          
          const SizedBox(height: 16),
          
          // Payment info section
          _buildPaymentInfoSection(orderDetail),
          
          const SizedBox(height: 16),
          
          // Order summary section
          _buildOrderSummarySection(orderDetail),
          
          const SizedBox(height: 22),
          
          // Review section - chỉ hiển thị cho đơn 1 mặt hàng
          if (orderDetail.items.length == 1)
            _buildReviewInputSection(orderDetail),
          
          const SizedBox(height: 16),
          
          // Cancel order button - ẩn với đơn đã giao và đã huỷ
          if (orderDetail.tinhTrangDonHang != 'da_giao' &&
              orderDetail.tinhTrangDonHang != 'hoan_thanh' &&
              orderDetail.tinhTrangDonHang != 'da_huy')
            _buildCancelOrderButton(context, orderDetail.maDonHang),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Order Timeline Section
  Widget _buildOrderTimelineSection(String currentStatus) {
    if (currentStatus == 'da_huy') return const SizedBox.shrink();

    int currentStep = 0;
    if (currentStatus == 'cho_giao_hang' || currentStatus == 'cho_shipper') {
      currentStep = 1;
    } else if (currentStatus == 'dang_lay_hang') {
      currentStep = 2;
    } else if (currentStatus == 'dang_giao') {
      currentStep = 3;
    } else if (currentStatus == 'da_giao' || currentStatus == 'hoan_thanh' || currentStatus == 'da_nhan_hang') {
      currentStep = 4;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Tiến trình giao hàng',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              // Nền đường nối (Lines)
              Positioned(
                top: 11,
                left: 35,
                right: 35,
                child: Row(
                  children: [
                    Expanded(child: _buildTimelineLine(1 <= currentStep)),
                    Expanded(child: _buildTimelineLine(2 <= currentStep)),
                    Expanded(child: _buildTimelineLine(3 <= currentStep)),
                    Expanded(child: _buildTimelineLine(4 <= currentStep)),
                  ],
                ),
              ),
              // Các điểm trạng thái (Dots + Text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimelineStep('Đã đặt', 0 <= currentStep, 0 < currentStep),
                  _buildTimelineStep('Chờ lấy', 1 <= currentStep, 1 < currentStep),
                  _buildTimelineStep('Đang lấy', 2 <= currentStep, 2 < currentStep),
                  _buildTimelineStep('Đang giao', 3 <= currentStep, 3 < currentStep),
                  _buildTimelineStep('Đã giao', 4 <= currentStep, false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isPassed) {
    return Container(
      height: 2,
      color: isPassed ? const Color(0xFF00B40F) : const Color(0xFFE0E0E0),
    );
  }

  Widget _buildTimelineStep(String title, bool isReached, bool isPassed) {
    final color = isReached ? const Color(0xFF00B40F) : const Color(0xFFE0E0E0);
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPassed ? color : Colors.white,
              border: Border.all(color: color, width: isReached ? 2 : 1.5),
            ),
            child: isPassed
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isReached
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      )
                    : null),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
              color: isReached ? const Color(0xFF00B40F) : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery info section
  Widget _buildDeliveryInfoSection(OrderDetailData orderDetail) {
    final address = orderDetail.diaChiGiaoHang;
    final statusColor = _getStatusColorFromString(orderDetail.tinhTrangDonHang);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Thông tin giao hàng',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF202020),
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  orderDetail.orderStatusDisplay,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (address != null) ...[
            _buildInfoRow('Người nhận', address.name),
            const SizedBox(height: 8),
            _buildInfoRow('Số điện thoại', address.phone),
            const SizedBox(height: 8),
            _buildInfoRow('Địa chỉ', address.address),
          ] else
            const Text(
              'Chưa có thông tin giao hàng',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          
          if (orderDetail.thoiGianGiaoHang != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Thời gian', _formatDateTime(orderDetail.thoiGianGiaoHang!)),
          ],
          
          if (orderDetail.tinhTrangDonHang == 'cho_shipper' || orderDetail.tinhTrangDonHang == 'dang_lay_hang') ...[
            Builder(
              builder: (context) {
                final physicalItems = orderDetail.items.where((i) => i.maNguyenLieu != 'NLQD01').toList();
                final totalPhysical = physicalItems.length;
                if (totalPhysical > 0) {
                  final pickedPhysical = physicalItems.where((i) => i.detailStatus == 'da_lay_hang').length;
                  final double progress = pickedPhysical / totalPhysical;
                  
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, color: Colors.orange.shade800, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shipper đang đi chợ (Đã lấy $pickedPhysical/$totalPhysical món)',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.orange.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade800),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          
          if (orderDetail.tinhTrangDonHang == 'dang_giao') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context, 
                    RouteName.orderTracking, 
                    arguments: orderDetail.maDonHang,
                  );
                },
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text(
                  'Xem Bản Đồ Theo Dõi Shipper',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B40F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Payment info section
  Widget _buildPaymentInfoSection(OrderDetailData orderDetail) {
    final payment = orderDetail.thanhToan;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  size: 20,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin thanh toán',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF202020),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (orderDetail.maThanhToan != null)
            _buildInfoRow('Mã thanh toán', orderDetail.maThanhToan!),
          
          if (payment != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Phương thức', payment.paymentMethodDisplay),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: payment.tinhTrangThanhToan == 'da_thanh_toan'
                        ? const Color(0xFF2F8000).withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.paymentStatusDisplay,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: payment.tinhTrangThanhToan == 'da_thanh_toan'
                          ? const Color(0xFF2F8000)
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (payment.thoiGianThanhToan != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Thời gian', _formatDateTime(payment.thoiGianThanhToan!)),
            ],
          ] else
            const Text(
              'Chưa có thông tin thanh toán',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Info row helper
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF202020),
            ),
          ),
        ),
      ],
    );
  }

  /// Order summary section
  Widget _buildOrderSummarySection(OrderDetailData orderDetail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F8000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Color(0xFF2F8000),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sản phẩm đã đặt',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF202020),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Items list from API - với review nếu nhiều hơn 1 mặt hàng
          ...orderDetail.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isMultiple = orderDetail.items.length > 1;
            return _buildOrderItemFromApi(
              item, 
              maDonHang: orderDetail.maDonHang,
              itemIndex: index, 
              showReview: isMultiple,
            );
          }),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.08),
          ),
          
          const SizedBox(height: 12),
          
          // Subtotal
          _buildSummaryRow('Tổng tạm tính', orderDetail.tongTien),
          
          const SizedBox(height: 11),
          
          // Shipping fee (free)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phí giao hàng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const Text(
                'Miễn phí',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2F8000),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.08),
          ),
          
          const SizedBox(height: 12),
          
          // Total
          _buildSummaryRow('Tổng cộng', orderDetail.tongTien, isBold: true),

          // Nút hoàn tiền
          if ((orderDetail.tinhTrangDonHang == 'da_giao' || orderDetail.tinhTrangDonHang == 'hoan_thanh') &&
              orderDetail.items.any((item) => !['cho_duyet', 'da_duyet', 'hoan_hang', 'tu_choi'].contains(item.detailStatus))) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showRefundDialog(orderDetail),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Yêu Cầu Hoàn Tiền',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Order item from API
  Widget _buildOrderItemFromApi(OrderItemDetail item, {required String maDonHang, int itemIndex = 0, bool showReview = false}) {
    final itemId = '${item.maNguyenLieu}_${item.maGianHang}_$itemIndex';
    final isSubmitted = _submittedItemReviews.contains(itemId);
    final isSubmitting = _isSubmittingItemReview[itemId] ?? false;
    
    // Initialize controllers if not exists
    if (showReview && !_itemReviewControllers.containsKey(itemId)) {
      _itemReviewControllers[itemId] = TextEditingController();
      _itemSelectedTags[itemId] = {};
      _itemRatings[itemId] = 0;
    }
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Product/Shop image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (item.nguyenLieu?.hinhAnh != null || item.gianHang?.hinhAnh != null)
                    ? Image.network(
                        item.nguyenLieu?.hinhAnh ?? item.gianHang!.hinhAnh!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nguyenLieu?.tenNguyenLieu ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.donViBan != null)
                      Text(
                        item.donViBan!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    if (item.gianHang != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 12, color: Color(0xFF2F8000)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${item.gianHang!.tenGianHang} - ${item.gianHang!.viTri ?? ''}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Color(0xFF2F8000),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.detailStatus == 'hoan_hang') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Đã hoàn tiền: ${item.cancelReason ?? ""}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Quantity and price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'x${item.soLuong}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(item.thanhTien)}đ',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF2F8000),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RouteName.chat),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: Color(0xFF00B40F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Review section for this item (khi có nhiều hơn 1 mặt hàng)
        if (showReview)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE4B5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _itemRatings[itemId] = index + 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          index < (_itemRatings[itemId] ?? 0) ? Icons.star : Icons.star_border,
                          size: 32,
                          color: index < (_itemRatings[itemId] ?? 0)
                              ? const Color(0xFFFFB800)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 12),
                
                // Review text field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _itemReviewControllers[itemId],
                    decoration: const InputDecoration(
                      hintText: 'Viết đánh giá cho sản phẩm này',
                      hintStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Quick tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickTags.map((tag) {
                    final isSelected = (_itemSelectedTags[itemId] ?? {}).contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _itemSelectedTags[itemId]?.remove(tag);
                          } else {
                            _itemSelectedTags[itemId]?.add(tag);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00B40F).withValues(alpha: 0.15) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00B40F) : const Color(0xFFDDD9D5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: isSelected ? const Color(0xFF00B40F) : const Color(0xFF666666),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Submit button
                if (isSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B40F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF00B40F), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Đã gửi đánh giá',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF00B40F),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: GestureDetector(
                      onTap: isSubmitting ? null : () => _submitItemReview(
                        maDonHang: maDonHang,
                        maNguyenLieu: item.maNguyenLieu,
                        maGianHang: item.maGianHang,
                        itemId: itemId,
                        tenNguyenLieu: item.nguyenLieu?.tenNguyenLieu ?? 'Sản phẩm',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B40F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Gửi đánh giá',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Summary row
  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    if (isBold) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF202020),
              ),
            ),
            Text(
              '${_formatPrice(amount)}đ',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF2F8000),
              ),
            ),
          ],
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          '${_formatPrice(amount)}đ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF202020),
          ),
        ),
      ],
    );
  }

  /// Get status color from string
  Color _getStatusColorFromString(String status) {
    switch (status) {
      case 'cho_xac_nhan':
        return const Color(0xFFFFA500);
      case 'da_xac_nhan':
        return const Color(0xFF4CAF50);
      case 'dang_giao':
        return const Color(0xFF9C27B0);
      case 'da_giao':
        return const Color(0xFF2F8000);
      case 'da_huy':
        return const Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }
  
  /// Format datetime
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Review input section - cho phép user đánh giá (cho đơn 1 mặt hàng)
  Widget _buildReviewInputSection(OrderDetailData orderDetail) {
    // Lấy item đầu tiên (vì chỉ 1 mặt hàng)
    final item = orderDetail.items.first;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Đánh giá sản phẩm',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF202020),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < _selectedRating 
                        ? const Color(0xFFFFB800) 
                        : const Color(0xFF202020),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // Review text field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Viết đánh giá cho sản phẩm...',
                hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 3,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00B40F).withValues(alpha: 0.15) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00B40F) : const Color(0xFFDDD9D5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isSelected ? const Color(0xFF00B40F) : const Color(0xFF666666),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Submit button
          Center(
            child: GestureDetector(
              onTap: _isSubmittingReview ? null : () => _submitOrderReview(
                maDonHang: orderDetail.maDonHang,
                maNguyenLieu: item.maNguyenLieu,
                maGianHang: item.maGianHang,
                tenNguyenLieu: item.nguyenLieu?.tenNguyenLieu ?? 'Sản phẩm',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B40F),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: _isSubmittingReview
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Gửi đánh giá',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  

  /// Cancel order button
  Widget _buildCancelOrderButton(BuildContext context, String maDonHang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: BlocBuilder<OrderDetailCubit, OrderDetailState>(
        builder: (context, state) {
          final isProcessing = state is OrderDetailProcessing;
          return GestureDetector(
            onTap: isProcessing ? null : () => _showCancelConfirmDialog(context, maDonHang),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFFF4444), width: 1.5),
              ),
              child: Center(
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF4444),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Huỷ đơn hàng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFFFF4444),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Show cancel confirmation dialog
  void _showCancelConfirmDialog(BuildContext context, String maDonHang) {
    final cubit = context.read<OrderDetailCubit>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4444), size: 28),
            SizedBox(width: 12),
            Text(
              'Xác nhận huỷ đơn',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF202020),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn huỷ đơn hàng này?\n\nSản phẩm sẽ được khôi phục về giỏ hàng của bạn.',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            color: Color(0xFF666666),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Không',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.cancelOrder(maDonHang);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Huỷ đơn',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format price helper
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
