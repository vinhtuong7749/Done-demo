import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/payment_cubit.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/geocoding_service.dart';

/// Màn hình thanh toán
/// 
/// Chức năng:
/// - Hiển thị tổng quan đơn hàng
/// - Chọn phương thức thanh toán
/// - Xác nhận đặt hàng
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  static const String routeName = '/payment';

  @override
  Widget build(BuildContext context) {
    // Lấy arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isBuyNow = arguments?['isBuyNow'] == true;
    final isFromCart = arguments?['isFromCart'] == true;
    
    print('💳 [PAYMENT PAGE] isBuyNow: $isBuyNow, isFromCart: $isFromCart');
    if (isBuyNow) {
      print('💳 [PAYMENT PAGE] Buy now data: $arguments');
    } else if (isFromCart) {
      print('💳 [PAYMENT PAGE] Cart data: ${arguments?['selectedItems']?.length} items');
    }
    
    return BlocProvider(
      create: (context) => PaymentCubit()..loadOrderSummary(
        isBuyNow: isBuyNow,
        isFromCart: isFromCart,
        orderData: arguments,
      ),
      child: const PaymentView(),
    );
  }
}

/// View của màn hình thanh toán
class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> with WidgetsBindingObserver {
  bool _hasProcessedReturn = false;
  
  // Controllers cho chỉnh sửa địa chỉ
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Controller cho ghi chú
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Khi app resume từ background (user quay lại từ browser)
    if (state == AppLifecycleState.resumed && !_hasProcessedReturn) {
      _hasProcessedReturn = true;
      
      print('💳 [PAYMENT PAGE] App resumed - checking payment status');
      
      // Đợi 1 giây để đảm bảo server đã xử lý xong callback từ VNPay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Gọi method check payment status
          context.read<PaymentCubit>().checkPaymentStatus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          // Show success dialog or navigate to success page
          _showSuccessDialog(context, state);
        } else if (state is PaymentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is PaymentPendingVNPay) {
          // Hiển thị dialog thông báo cần thanh toán
          _showPendingPaymentDialog(context, state);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [
            // Header with background
            _buildHeader(context),
            
            // Content
            Expanded(
              child: BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  if (state is PaymentLoading || state is PaymentProcessing) {
                    return const BuyerLoading(
              message: 'Đang đặt hàng...',
            );
                  }

                  if (state is PaymentLoaded) {
                    return _buildContent(context, state);
                  }
                  
                  if (state is PaymentPendingVNPay) {
                    // Hiển thị UI chờ thanh toán
                    return _buildPendingPaymentContent(context, state);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            
            // Bottom navigation
            
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/img/arrow_left_cart.svg',
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  const Text(
                    'Tổng quan đơn hàng',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.1,
                      color: Color(0xFF000000),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Placeholder to balance
                  const SizedBox(width: 40),
                ],
              ),
              
              const SizedBox(height: 8),
              
              
              
              
            ],
          ),
        ),
      ),
    );
  }

  /// Content
  Widget _buildContent(BuildContext context, PaymentLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery address
          _buildDeliveryAddress(context, state.orderSummary),
          
          const SizedBox(height: 16),
          
          // Notes section
          _buildAdditionalInfo(context, state.orderSummary),
          
          const SizedBox(height: 16),
          
          // Order items
          _buildOrderItems(state.orderSummary),
          
          const SizedBox(height: 16),
          
          // Delivery time
          _buildDeliveryTime(context, state.orderSummary, state.timeSlotId),
          
          const SizedBox(height: 24),
          
          // Order summary
          _buildOrderSummary(state.orderSummary),
          
          const SizedBox(height: 24),
          
          // Payment method
          _buildPaymentMethod(context, state),
          
          const SizedBox(height: 24),
          
          // Total section
          _buildTotalSection(state.orderSummary),
          
          const SizedBox(height: 24),
          
          // Order button
          _buildOrderButton(context, state),
        ],
      ),
    );
  }

  /// Delivery address section
  Widget _buildDeliveryAddress(BuildContext context, OrderSummary orderSummary) {
    return GestureDetector(
      onTap: () => _showAddressEditDialog(context, orderSummary),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00B40F).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00B40F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF00B40F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const Text(
                        'Thay đổi',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF00B40F),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  orderSummary.customerName,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  orderSummary.phoneNumber,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
                  const SizedBox(height: 4),
                  Text(
                    orderSummary.deliveryAddress,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Additional info / Notes section
  Widget _buildAdditionalInfo(BuildContext context, OrderSummary orderSummary) {
    if (_notesController.text.isEmpty && orderSummary.notes != null) {
      _notesController.text = orderSummary.notes!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                color: Color(0xFF666666),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ghi chú cho gian hàng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF202020),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            onChanged: (value) => context.read<PaymentCubit>().updateNotes(value),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập thông tin cần lưu ý cho gian hàng...',
              hintStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              filled: true,
              fillColor: const Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog chỉnh sửa địa chỉ
  void _showAddressEditDialog(BuildContext context, OrderSummary orderSummary) {
    _nameController.text = orderSummary.customerName;
    _phoneController.text = orderSummary.phoneNumber;
    _addressController.text = orderSummary.deliveryAddress;
    
    final paymentCubit = context.read<PaymentCubit>();
    paymentCubit.clearSuggestions(); // Clear cũ

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: paymentCubit,
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thông tin nhận hàng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Color(0xFF202020),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Họ và tên'),
                          const SizedBox(height: 8),
                          _buildEditTextField(_nameController, 'Nhập tên người nhận'),
                          
                          const SizedBox(height: 16),
                          
                          _buildFieldLabel('Số điện thoại'),
                          const SizedBox(height: 8),
                          _buildEditTextField(
                            _phoneController, 
                            'Nhập số điện thoại', 
                            keyboardType: TextInputType.phone
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildFieldLabel('Địa chỉ chi tiết'),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _buildEditTextField(
                                _addressController, 
                                'Nhập hoặc chọn địa chỉ giao hàng',
                                maxLines: 2,
                                onChanged: (value) => paymentCubit.searchAddress(value),
                              ),
                              
                              if (state is PaymentLoaded && (state.isSearchingAddress || state.addressSuggestions.isNotEmpty))
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  constraints: const BoxConstraints(maxHeight: 250),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: state.isSearchingAddress
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B40F))),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: state.addressSuggestions.length,
                                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                                          itemBuilder: (context, index) {
                                            final suggestion = state.addressSuggestions[index];
                                            return ListTile(
                                              leading: const Icon(Icons.location_on_outlined, color: Color(0xFF00B40F), size: 20),
                                              title: Text(
                                                suggestion.displayName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 14,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              onTap: () {
                                                _addressController.text = suggestion.displayName;
                                                paymentCubit.selectAddressSuggestion(suggestion);
                                              },
                                            );
                                          },
                                        ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      paymentCubit.updateAddress(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                      );
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B40F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B40F).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Xác nhận địa chỉ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
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
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Color(0xFF666666),
      ),
    );
  }

  Widget _buildEditTextField(
    TextEditingController controller, 
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Color(0xFF999999),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Order items section - Nhóm theo gian hàng
  Widget _buildOrderItems(OrderSummary orderSummary) {
    // Nhóm items theo shop
    final itemsByShop = <String, List<OrderItem>>{};
    for (final item in orderSummary.items) {
      if (!itemsByShop.containsKey(item.shopName)) {
        itemsByShop[item.shopName] = [];
      }
      itemsByShop[item.shopName]!.add(item);
    }

    return Column(
      children: itemsByShop.entries.map((entry) {
        final shopName = entry.key;
        final items = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop name with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color(0xFF00B40F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      shopName,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1.1,
                        color: Color(0xFF202020),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Divider
              Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              
              const SizedBox(height: 16),
              
              // Products của shop này
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0) const SizedBox(height: 16),
                    _buildOrderItem(item),
                  ],
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Single order item
  Widget _buildOrderItem(OrderItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(item.productImage),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.375,
                    color: Color(0xFF202020),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Weight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.weight}${item.unit}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Price
                Row(
                  children: [
                    Text(
                      '${_formatPrice(item.totalPrice)}đ',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.29,
                        color: Color(0xFFFF0000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery time with slot selection
  Widget _buildDeliveryTime(BuildContext context, OrderSummary orderSummary, String selectedSlotId) {
    // Current valid slots from API
    final slots = [
      {'id': 'KG01', 'name': 'Sáng', 'time': '06:30 - 07:00'},
      {'id': 'KG02', 'name': 'Sáng', 'time': '07:00 - 07:30'},
      {'id': 'KG03', 'name': 'Sáng', 'time': '07:30 - 08:00'},
      {'id': 'KG04', 'name': 'Sáng', 'time': '08:00 - 08:30'},
      {'id': 'KG05', 'name': 'Sáng', 'time': '08:30 - 09:00'},
      {'id': 'KG06', 'name': 'Sáng', 'time': '09:00 - 09:30'},
      {'id': 'KG07', 'name': 'Sáng', 'time': '09:30 - 10:00'},
      {'id': 'KG08', 'name': 'Sáng', 'time': '10:00 - 10:30'},
      {'id': 'KG09', 'name': 'Sáng', 'time': '10:30 - 11:00'},
      {'id': 'KG10', 'name': 'Trưa', 'time': '11:00 - 11:30'},
      {'id': 'KG11', 'name': 'Trưa', 'time': '11:30 - 12:00'},
      {'id': 'KG12', 'name': 'Trưa', 'time': '12:00 - 12:30'},
      {'id': 'KG13', 'name': 'Chiều', 'time': '14:30 - 15:00'},
      {'id': 'KG14', 'name': 'Chiều', 'time': '15:00 - 15:30'},
      {'id': 'KG15', 'name': 'Chiều', 'time': '15:30 - 16:00'},
      {'id': 'KG16', 'name': 'Chiều', 'time': '16:00 - 16:30'},
      {'id': 'KG17', 'name': 'Chiều', 'time': '16:30 - 17:00'},
      {'id': 'KG18', 'name': 'Tối', 'time': '17:00 - 17:30'},
      {'id': 'KG19', 'name': 'Tối', 'time': '17:30 - 18:00'},
      {'id': 'KG20', 'name': 'Tối', 'time': '18:00 - 18:30'},
      {'id': 'KG21', 'name': 'Tối', 'time': '18:30 - 19:00'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời gian giao hàng',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF202020),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = selectedSlotId == slot['id'];
              return _buildTimeSlotOption(
                context, 
                slot['id']!, 
                slot['name']!, 
                slot['time']!, 
                isSelected
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotOption(BuildContext context, String id, String title, String time, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<PaymentCubit>().updateTimeSlotId(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00B40F) : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: isSelected ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B40F),
                    shape: BoxShape.circle,
                  ),
                ),
              ) : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 15,
                color: isSelected ? const Color(0xFF00B40F) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 16), // Replaced Spacer to prevent RenderFlex crash in horizontal list
            Text(
              time,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isSelected ? const Color(0xFF00B40F) : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Order summary section
  Widget _buildOrderSummary(OrderSummary orderSummary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
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
          const Text(
            'Tóm tắt đơn hàng',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.1,
              color: Color(0xFF202020),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          
          const SizedBox(height: 16),
          
          // Subtotal
          _buildSummaryRow('Tổng phụ', orderSummary.subtotal, false),
          
          const SizedBox(height: 12),
          
          // Shipping
          // _buildSummaryRow('Vận chuyển', orderSummary.shippingFee, false),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          
          const SizedBox(height: 16),
          
          // Total
          _buildSummaryRow('Tổng cộng', orderSummary.total, true),
        ],
      ),
    );
  }

  /// Summary row
  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            fontSize: isTotal ? 18 : 16,
            height: 1.29,
            color: isTotal ? const Color(0xFF000000) : const Color(0xFF666666),
          ),
        ),
        Text(
          '${_formatPrice(amount)}đ',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            fontSize: isTotal ? 20 : 16,
            height: 1.29,
            color: isTotal ? const Color(0xFF00B40F) : const Color(0xFF000000),
          ),
        ),
      ],
    );
  }

  /// Payment method section
  Widget _buildPaymentMethod(BuildContext context, PaymentLoaded state) {
    final cubit = context.read<PaymentCubit>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
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
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.1,
              color: Color(0xFF202020),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          
          const SizedBox(height: 16),
          
          // Cash on delivery
          _buildPaymentMethodOption(
            context,
            PaymentMethod.cashOnDelivery,
            'Thanh toán khi giao',
            'assets/img/payment_cash_icon.png',
            state.selectedPaymentMethod == PaymentMethod.cashOnDelivery,
            () => cubit.selectPaymentMethod(PaymentMethod.cashOnDelivery),
          ),
          
          // VNPay
          _buildPaymentMethodOption(
            context,
            PaymentMethod.vnpay,
            'VNpay',
            'assets/img/payment_vnpay_logo-3a23a6.png',
            state.selectedPaymentMethod == PaymentMethod.vnpay,
            () => cubit.selectPaymentMethod(PaymentMethod.vnpay),
            isLogo: true,
          ),
        ],
      ),
    );
  }

  /// Payment method option
  Widget _buildPaymentMethodOption(
    BuildContext context,
    PaymentMethod method,
    String label,
    String iconPath,
    bool isSelected,
    VoidCallback onTap, {
    bool isLogo = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF00B40F).withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF00B40F)
                    : Colors.black.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isLogo
                      ? Image.asset(
                          iconPath,
                          width: 40,
                          height: 15,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          iconPath,
                          width: 30,
                          height: 30,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 17,
                      height: 1.1,
                      color: const Color(0xFF202020),
                    ),
                  ),
                ),
                
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF00B40F)
                          : Colors.black.withOpacity(0.3),
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF00B40F) : Colors.white,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Total section
  Widget _buildTotalSection(OrderSummary orderSummary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B40F).withValues(alpha: 0.15),
            const Color(0xFF00B40F).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00B40F).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${orderSummary.totalItemCount} mặt hàng',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          Text(
            '${_formatPrice(orderSummary.total)}đ',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.2,
              color: Color(0xFF00B40F),
            ),
          ),
        ],
      ),
    );
  }

  /// Order button
  Widget _buildOrderButton(BuildContext context, PaymentLoaded state) {
    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, currentState) {
        final isProcessing = currentState is PaymentProcessing;
        
        return GestureDetector(
          onTap: isProcessing
              ? null
              : () => context.read<PaymentCubit>().processPayment(),
          child: Container(
            height: 59,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProcessing
                    ? [
                        const Color(0xFF00B40F),
                        const Color(0xFF00B40F),
                      ]
                    : [
                        Color(0xFF00B40F),
                        Color(0xFF00B40F),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: isProcessing
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF00B40F).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Xác nhận đặt hàng',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.21,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, PaymentSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00B40F),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.21,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã đơn hàng: ${state.orderId}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  // Navigate to order detail page with order ID
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteName.orderDetail,
                    (route) => route.settings.name == RouteName.main || route.isFirst,
                    arguments: state.orderId,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B40F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Xem chi tiết đơn hàng',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog thông báo cần thanh toán VNPay
  void _showPendingPaymentDialog(BuildContext context, PaymentPendingVNPay state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFFFF9500),
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Chờ thanh toán',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF202020),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Order code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mã đơn: ${state.orderId}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Hủy button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pop(); // Quay lại trang trước
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Thanh toán lại button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Gọi lại thanh toán VNPay
                          context.read<PaymentCubit>().processPayment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B40F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Thanh toán',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// UI hiển thị khi đang chờ thanh toán VNPay
  Widget _buildPendingPaymentContent(BuildContext context, PaymentPendingVNPay state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Warning icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payment,
              color: Color(0xFFFF9500),
              size: 50,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Đơn hàng chờ thanh toán',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Color(0xFF202020),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Order code card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF9500).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFFF9500),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mã đơn hàng: ${state.orderId}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF202020),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Thanh toán button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<PaymentCubit>().processPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B40F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Thanh toán ngay',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Quay lại button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Quay lại',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build product image - support both URL and asset
  Widget _buildProductImage(String imagePath) {
    final isNetworkImage = imagePath.startsWith('http://') || 
                          imagePath.startsWith('https://');
    
    final placeholderWidget = Container(
      width: 91,
      height: 91,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );

    if (imagePath.isEmpty) {
      return placeholderWidget;
    }

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: 91,
        height: 91,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final expectedBytes = loadingProgress.expectedTotalBytes;
          final value = (expectedBytes != null && expectedBytes > 0)
              ? loadingProgress.cumulativeBytesLoaded / expectedBytes
              : null;
              
          return Container(
            width: 91,
            height: 91,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                color: const Color(0xFF00B40F),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => placeholderWidget,
      );
    } else {
      return Image.asset(
        imagePath,
        width: 91,
        height: 91,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholderWidget,
      );
    }
  }

  /// Format price helper
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
