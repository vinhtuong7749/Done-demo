import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/services/vnpay_service.dart';
import '../../../../../core/services/cart_api_service.dart';
import '../../../../../core/services/user_profile_service.dart';
import '../../../../../core/services/geocoding_service.dart';
import 'dart:async';

part 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final GeocodingService _geocodingService = GeocodingService();
  Timer? _debounce;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
  OrderSummary? _orderSummary;
  String? _maDonHang; // Mã đơn hàng từ API cart hoặc tạo mới
  bool _isBuyNow = false;
  
  PaymentCubit() : super(PaymentInitial());

  /// Tải thông tin đơn hàng
  Future<void> loadOrderSummary({
    bool isBuyNow = false,
    bool isFromCart = false,
    Map<String, dynamic>? orderData,
  }) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🎯 [PAYMENT] Bắt đầu tải thông tin đơn hàng');
      AppLogger.info('🎯 [PAYMENT] isBuyNow: $isBuyNow, isFromCart: $isFromCart');
    }

    try {
      emit(PaymentLoading());

      _isBuyNow = isBuyNow;

      if (isBuyNow && orderData != null) {
        // Mua ngay - tạo order summary từ dữ liệu truyền vào
        print('💳 [PAYMENT CUBIT] Creating order from buy now data');
        _orderSummary = _createOrderFromBuyNowData(orderData);
      } else if (isFromCart && orderData != null) {
        // Từ giỏ hàng - tạo order summary từ các items đã chọn
        print('💳 [PAYMENT CUBIT] Creating order from cart data');
        _orderSummary = _createOrderFromCartData(orderData);
      } else {
        // Fallback - Mock data
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if cubit is still open before continuing
        if (isClosed) return;
        
        _orderSummary = _generateMockOrderSummary();
      }

      // Gắn thông tin user từ /auth/me nếu có
      _orderSummary = await _attachUserInfo(_orderSummary!);

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [PAYMENT] Tải thành công thông tin đơn hàng');
        AppLogger.info('💰 [PAYMENT] Tổng tiền: ${_orderSummary!.total}đ');
      }

      // Lưu mã đơn hàng nếu có (từ tham số truyền vào)
      final newMaDonHang = orderData?['orderCode'] as String?;
      if (newMaDonHang != null) {
        _maDonHang = newMaDonHang;
      }

      emit(PaymentLoaded(
        orderSummary: _orderSummary!,
        selectedPaymentMethod: _selectedPaymentMethod,
        orderCode: _maDonHang,
        timeSlotId: 'KG10', // Default on load (11:00 - 11:30)
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [PAYMENT] Lỗi khi tải thông tin: ${e.toString()}');
      }
      if (!isClosed) {
        emit(PaymentFailure(
          errorMessage: 'Không thể tải thông tin đơn hàng: ${e.toString()}',
        ));
      }
    }
  }

  /// Tạo order summary từ dữ liệu "Mua ngay"
  OrderSummary _createOrderFromBuyNowData(Map<String, dynamic> data) {
    print('💳 [PAYMENT CUBIT] Buy now data: $data');
    
    final shopId = data['maGianHang'] as String? ?? '';
    final shopName = data['tenGianHang'] as String? ?? '';

    // Parse giá từ string (ví dụ: "89,000 đ" -> 89000)
    final priceStr = data['gia'] as String? ?? '0';
    final priceValue = double.tryParse(
      priceStr.replaceAll(RegExp(r'[^\d]'), '')
    ) ?? 0;
    
    final soLuong = data['soLuong'] as int? ?? 1;
    final totalPrice = priceValue * soLuong;
    
    return OrderSummary(
      customerName: 'Phạm Thị Quỳnh Như',
      phoneNumber: '(+84) 03******12',
      deliveryAddress: '123 Đa Mặn, Mỹ An, Ngũ Hành Sơn, Đà Nẵng, Việt Nam',
      estimatedDelivery: 'Nhận vào 2 giờ tới',
      items: [
        OrderItem(
          id: data['maNguyenLieu'] as String? ?? '',
          shopId: shopId,
          shopName: shopName,
          productName: data['tenNguyenLieu'] as String? ?? '',
          productImage: data['hinhAnh'] as String? ?? 'assets/img/payment_product.png',
          price: priceValue,
          weight: 1.0,
          unit: data['donVi'] as String? ?? 'KG',
          quantity: soLuong,
        ),
      ],
      subtotal: totalPrice,
      total: totalPrice,
    );
  }

  /// Tạo order summary từ dữ liệu giỏ hàng
  OrderSummary _createOrderFromCartData(Map<String, dynamic> data) {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('💳 [PAYMENT CUBIT] Cart data: $data');
    }
    
    final selectedItems = data['selectedItems'] as List<dynamic>? ?? [];
    final totalAmount = data['totalAmount'] as double? ?? 0;
    
    // Lưu mã đơn hàng nếu có (từ cart API)
    _maDonHang = data['orderCode'] as String?;
    
    // Convert selected items to OrderItem list
    final orderItems = selectedItems.map((item) {
      final itemMap = item as Map<String, dynamic>;
      final priceStr = itemMap['gia'] as String? ?? '0';
      final priceValue = double.tryParse(
        priceStr.replaceAll(RegExp(r'[^\d.]'), '')
      ) ?? 0;
      
      // Lấy shopId - đảm bảo không empty
      final shopId = itemMap['maGianHang'] as String? ?? '';
      
      if (AppConfig.enableApiLogging) {
        AppLogger.info('💳 [PAYMENT] Item: maNguyenLieu=${itemMap['maNguyenLieu']}, maGianHang=$shopId');
      }
      
      return OrderItem(
        id: itemMap['maNguyenLieu'] as String? ?? '',
        shopId: shopId,
        shopName: itemMap['tenGianHang'] as String? ?? '',
        productName: itemMap['tenNguyenLieu'] as String? ?? '',
        productImage: itemMap['hinhAnh'] as String? ?? '',
        price: priceValue,
        weight: 1.0,
        unit: 'Cái',
        quantity: itemMap['soLuong'] as int? ?? 1,
      );
    }).toList();
    
    return OrderSummary(
      customerName: 'Phạm Thị Quỳnh Như',
      phoneNumber: '(+84) 03******12',
      deliveryAddress: '123 Đa Mặn, Mỹ An, Ngũ Hành Sơn, Đà Nẵng, Việt Nam',
      estimatedDelivery: 'Nhận vào 2 giờ tới',
      items: orderItems,
      subtotal: totalAmount,
      total: totalAmount ,
    );
  }

  /// Chọn phương thức thanh toán
  void selectPaymentMethod(PaymentMethod method) {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('💳 [PAYMENT] Chọn phương thức: ${method.name}');
    }

    _selectedPaymentMethod = method;

    if (_orderSummary != null) {
      final currentState = state;
      emit(PaymentLoaded(
        orderSummary: _orderSummary!,
        selectedPaymentMethod: _selectedPaymentMethod,
        orderCode: _maDonHang,
        timeSlotId: currentState is PaymentLoaded ? currentState.timeSlotId : 'KG10',
      ));
    }
  }

  /// Cập nhật thông tin giao hàng
  void updateAddress({
    required String name,
    required String phone,
    required String address,
  }) {
    if (_orderSummary != null) {
      _orderSummary = _orderSummary!.copyWith(
        customerName: name,
        phoneNumber: phone,
        deliveryAddress: address,
      );
      
      final currentState = state;
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          orderSummary: _orderSummary!,
          addressSuggestions: [], // Clear suggestions khi đã confirm
        ));
      } else {
        emit(PaymentLoaded(
          orderSummary: _orderSummary!,
          selectedPaymentMethod: _selectedPaymentMethod,
          orderCode: _maDonHang,
        ));
      }
    }
  }

  /// Tìm kiếm gợi ý địa chỉ
  void searchAddress(String query) {
    final currentState = state;
    if (currentState is! PaymentLoaded) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length >= 3) {
        emit(currentState.copyWith(isSearchingAddress: true, addressSuggestions: []));
        
        final suggestions = await _geocodingService.searchAddress(query);
        
        if (isClosed) return;
        
        final newState = state;
        if (newState is PaymentLoaded) {
          emit(newState.copyWith(
            isSearchingAddress: false,
            addressSuggestions: suggestions,
          ));
        }
      } else {
        emit(currentState.copyWith(addressSuggestions: []));
      }
    });
  }

  /// Chọn một gợi ý địa chỉ
  void selectAddressSuggestion(MapSuggestion suggestion) {
    if (_orderSummary != null) {
      _orderSummary = _orderSummary!.copyWith(
        deliveryAddress: suggestion.displayName,
      );
      
      final currentState = state;
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          orderSummary: _orderSummary!,
          addressSuggestions: [],
        ));
      }
    }
  }

  /// Xóa danh sách gợi ý
  void clearSuggestions() {
    final currentState = state;
    if (currentState is PaymentLoaded) {
      emit(currentState.copyWith(addressSuggestions: []));
    }
  }

  /// Cập nhật ghi chú
  void updateNotes(String notes) {
    if (_orderSummary != null) {
      _orderSummary = _orderSummary!.copyWith(notes: notes);
      
      final currentState = state;
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(orderSummary: _orderSummary!));
      }
    }
  }

  /// Cập nhật Time Slot ID
  void updateTimeSlotId(String slotId) {
    final currentState = state;
    if (currentState is PaymentLoaded) {
      emit(currentState.copyWith(timeSlotId: slotId));
    }
  }

  /// Check payment status (gọi khi app resume từ browser VNPay)
  /// Gọi API để kiểm tra trạng thái thanh toán thực tế
  Future<void> checkPaymentStatus() async {
    final currentState = state;
    String? maDonHang;
    
    // Lấy mã đơn hàng từ state hoặc biến instance
    if (currentState is PaymentLoaded && currentState.orderCode != null) {
      maDonHang = currentState.orderCode;
    } else {
      maDonHang = _maDonHang;
    }
    
    if (maDonHang == null || maDonHang.isEmpty) {
      if (AppConfig.enableApiLogging) {
        AppLogger.warning('⚠️ [PAYMENT] No order code available');
      }
      return;
    }

    if (AppConfig.enableApiLogging) {
      AppLogger.info('💳 [PAYMENT] App resumed from browser');
      AppLogger.info('💳 [PAYMENT] Checking payment status for: $maDonHang');
    }

    try {
      emit(PaymentProcessing());
      
      // Gọi API để kiểm tra trạng thái đơn hàng
      final vnpayService = VNPayService();
      final orderStatus = await vnpayService.getOrderStatus(maDonHang);
      
      if (AppConfig.enableApiLogging) {
        AppLogger.info('💳 [PAYMENT] Order status: ${orderStatus.trangThai}');
        AppLogger.info('💳 [PAYMENT] Is paid: ${orderStatus.isPaid}');
      }
      
      if (isClosed) return;
      
      if (orderStatus.isPaid) {
        // Thanh toán thành công
        emit(PaymentSuccess(
          message: 'Thanh toán thành công!',
          orderId: maDonHang,
        ));
      } else if (orderStatus.isPending || orderStatus.trangThai == 'chua_xac_nhan') {
        // Đang chờ thanh toán - hiển thị thông báo yêu cầu thanh toán
        emit(PaymentPendingVNPay(
          orderId: maDonHang,
          message: 'Vui lòng thanh toán để xác nhận đơn hàng',
          orderSummary: _orderSummary!,
        ));
      } else if (orderStatus.isCancelled) {
        // Thanh toán bị hủy
        emit(const PaymentFailure(
          errorMessage: 'Thanh toán đã bị hủy. Vui lòng thử lại.',
        ));
      } else {
        // Trạng thái khác - navigate đến order detail để xem chi tiết
        emit(PaymentSuccess(
          message: 'Đơn hàng đã được xử lý!',
          orderId: maDonHang,
        ));
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [PAYMENT] Error checking status: $e');
      }
      if (!isClosed) {
        // Nếu lỗi, vẫn navigate đến order detail để user có thể xem
        emit(PaymentSuccess(
          message: 'Vui lòng kiểm tra trạng thái đơn hàng',
          orderId: maDonHang,
        ));
      }
    }
  }

  /// Verify payment result từ VNPay callback
  Future<void> verifyVNPayReturn(Map<String, String> queryParams) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('💳 [PAYMENT] Verifying VNPay return...');
      AppLogger.info('💳 [PAYMENT] Query params: $queryParams');
    }

    try {
      emit(PaymentProcessing());

      final vnpayService = VNPayService();
      final result = await vnpayService.verifyPaymentReturn(
        queryParams: queryParams,
      );

      if (AppConfig.enableApiLogging) {
        AppLogger.info('💳 [PAYMENT] Verify result: ${result.success}');
        AppLogger.info('💳 [PAYMENT] Message: ${result.message}');
        AppLogger.info('💳 [PAYMENT] Order: ${result.maDonHang}');
        AppLogger.info('💳 [PAYMENT] Clear cart: ${result.clearCart}');
      }

      if (!isClosed) {
        if (result.success) {
          emit(PaymentSuccess(
            message: result.message,
            orderId: result.maDonHang,
          ));
        } else {
          emit(PaymentFailure(
            errorMessage: result.message,
          ));
        }
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [PAYMENT] Verify error: $e');
      }
      if (!isClosed) {
        emit(PaymentFailure(
          errorMessage: 'Không thể xác minh kết quả thanh toán: ${e.toString()}',
        ));
      }
    }
  }

  /// Xử lý thanh toán
  Future<void> processPayment() async {
    if (_orderSummary == null) {
      if (!isClosed) {
        emit(const PaymentFailure(
          errorMessage: 'Không có thông tin đơn hàng',
        ));
      }
      return;
    }

    if (AppConfig.enableApiLogging) {
      AppLogger.info('💳 [PAYMENT] Bắt đầu xử lý thanh toán');
      AppLogger.info('💳 [PAYMENT] Phương thức: ${_selectedPaymentMethod.name}');
      AppLogger.info('💰 [PAYMENT] Tổng tiền: ${_orderSummary!.total}đ');
    }

    try {
      emit(PaymentProcessing());

      if (_selectedPaymentMethod == PaymentMethod.vnpay) {
        // Xử lý thanh toán VNPay
        // Bước 1: Gọi API /api/buyer/cart/checkout để tạo đơn hàng
        if (AppConfig.enableApiLogging) {
          AppLogger.info('💳 [PAYMENT] Step 1: Calling cart checkout API...');
        }
        
        // Validate items trước khi gọi API
        for (final item in _orderSummary!.items) {
          if (item.id.isEmpty) {
            throw Exception('Thiếu mã nguyên liệu cho sản phẩm: ${item.productName}');
          }
          if (item.shopId.isEmpty) {
            throw Exception('Thiếu mã gian hàng cho sản phẩm: ${item.productName}');
          }
        }
        
        // Lấy selectedItems từ _orderSummary với format đúng API yêu cầu
        // API CheckoutBody cần: ingredient_id và stall_id
        final selectedItems = _orderSummary!.items.map((item) => {
          'ingredient_id': item.id,
          'stall_id': item.shopId,
        }).toList();

        if (selectedItems.isEmpty) {
          throw Exception('Không có sản phẩm nào được chọn để thanh toán');
        }

        // Chuẩn bị thông tin người nhận (re-use logic với COD)
        final userProfileService = UserProfileService();
        String userName = _orderSummary!.customerName;
        String phoneNumber =
            _normalizePhoneNumber(_orderSummary?.phoneNumber ?? '');
        if (phoneNumber.isEmpty) {
          phoneNumber = '0912345678';
        }
        // Ưu tiên địa chỉ user đã thay đổi trên trang thanh toán
        String address = _orderSummary!.deliveryAddress;

        try {
          final profileResponse = await userProfileService.getProfile();
          final profile = profileResponse.data;

          if (profile.tenNguoiDung.isNotEmpty) {
            userName = profile.tenNguoiDung;
          }

          if (profile.sdt != null && profile.sdt!.isNotEmpty) {
            final normalized = _normalizePhoneNumber(profile.sdt!);
            if (normalized.isNotEmpty) {
              phoneNumber = normalized;
            }
          }

          // KHÔNG ghi đè address từ profile nữa
          // Giữ nguyên address mà user đã chọn trên trang thanh toán
        } catch (_) {
          // bỏ qua, giữ fallback
        }

        if (_normalizePhoneNumber(phoneNumber).isEmpty) {
          phoneNumber = '0912345678';
        }

        // Loại bỏ đuôi ', Việt Nam' / ', Vietnam' để backend ghi nhận được
        address = _cleanAddressForBackend(address);

        final recipient = {
          'name': userName,
          'phone': phoneNumber,
          'address': address,
          'notes': _orderSummary?.notes ?? '',
        };
        
        if (AppConfig.enableApiLogging) {
          AppLogger.info('💳 [PAYMENT] Selected items: $selectedItems');
          AppLogger.info('💳 [PAYMENT] Recipient: $recipient');
        }
        
        final cartApiService = CartApiService();

        // Nếu là Mua ngay, đảm bảo item đã vào giỏ trước khi checkout
        if (_isBuyNow) {
          for (final item in _orderSummary!.items) {
            await cartApiService.addToCart(
              maNguyenLieu: item.id,
              maGianHang: item.shopId,
              soLuong: item.quantity.toDouble(),
            );
          }
        }

        // Gọi API checkout
        final currentState = state;
        final checkoutResponse = await cartApiService.checkout(
          selectedItems: selectedItems,
          // Backend chỉ chấp nhận 'chuyen_khoan' hoặc 'tien_mat'.
          // Dùng 'chuyen_khoan' để tạo đơn cho VNPay.
          paymentMethod: 'chuyen_khoan',
          recipient: recipient,
          deliveryAddress: address,
          timeSlotId: currentState is PaymentLoaded ? currentState.timeSlotId : 'KG10',
        );
        
        if (AppConfig.enableApiLogging) {
          AppLogger.info('📦 [PAYMENT] Checkout response:');
          AppLogger.info('   success: ${checkoutResponse.success}');
          AppLogger.info('   maDonHang: "${checkoutResponse.maDonHang}"');
          AppLogger.info('   maThanhToan: "${checkoutResponse.maThanhToan}"');
          AppLogger.info('   tongTien: ${checkoutResponse.tongTien}');
        }
        
        if (!checkoutResponse.success || checkoutResponse.maDonHang.isEmpty) {
          throw Exception('Checkout failed: Không nhận được mã đơn hàng');
        }
        
        if (checkoutResponse.maThanhToan.isEmpty) {
          throw Exception('Checkout failed: Không nhận được mã thanh toán');
        }
        
        final maDonHang = checkoutResponse.maDonHang;
        final maThanhToan = checkoutResponse.maThanhToan;
        _maDonHang = maDonHang; // Lưu lại để dùng sau
        
        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [PAYMENT] Checkout success!');
          AppLogger.info('📝 [PAYMENT] ma_don_hang: $maDonHang');
          AppLogger.info('💳 [PAYMENT] ma_thanh_toan: $maThanhToan');
          AppLogger.info('💰 [PAYMENT] tong_tien: ${checkoutResponse.tongTien}');
          AppLogger.info('📦 [PAYMENT] items_checkout: ${checkoutResponse.itemsCheckout}');
          AppLogger.info('💳 [PAYMENT] Step 2: Creating VNPay payment...');
        }
        
        // Bước 2: Gọi API /api/payment/vnpay/checkout với ma_thanh_toan từ bước 1
        // Input: { "ma_thanh_toan": "TTE4X3PXWT", "bankCode": "NCB" }
        final vnpayService = VNPayService();
        final vnpayResponse = await vnpayService.createVNPayCheckout(
          maThanhToan: maThanhToan,
          bankCode: 'NCB',
        );
        
        if (vnpayResponse.success && vnpayResponse.redirect.isNotEmpty) {
          // Mở URL VNPay trong trình duyệt
          final url = Uri.parse(vnpayResponse.redirect);
          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication, // Mở trong trình duyệt mặc định
            );
            
            if (AppConfig.enableApiLogging) {
              AppLogger.info('🎉 [PAYMENT] Đã mở VNPay payment URL');
              AppLogger.info('📝 [PAYMENT] Mã đơn hàng: $maDonHang');
              AppLogger.info('📝 [PAYMENT] Mã thanh toán: ${vnpayResponse.maThanhToan}');
            }
            
            // Quay lại state PaymentLoaded để chờ user thanh toán xong và quay lại app
            // Khi app resume, checkPaymentStatus() sẽ được gọi
            if (!isClosed) {
              emit(PaymentLoaded(
                orderSummary: _orderSummary!,
                selectedPaymentMethod: _selectedPaymentMethod,
                orderCode: maDonHang, // Giữ mã đơn hàng để check status sau
              ));
            }
          } else {
            throw Exception('Không thể mở URL thanh toán VNPay');
          }
        } else {
          throw Exception('Không nhận được URL thanh toán từ VNPay');
        }
      } else {
        // Thanh toán khi nhận hàng (COD)
        if (AppConfig.enableApiLogging) {
          AppLogger.info('💳 [PAYMENT] Processing COD payment...');
        }

        // Validate items
        for (final item in _orderSummary!.items) {
          if (item.id.isEmpty) {
            throw Exception(
                'Thiếu mã nguyên liệu cho sản phẩm: ${item.productName}');
          }
          if (item.shopId.isEmpty) {
            throw Exception(
                'Thiếu mã gian hàng cho sản phẩm: ${item.productName}');
          }
        }

        // Lấy selectedItems từ _orderSummary
        // API CheckoutBody cần: ingredient_id và stall_id
        final selectedItems = _orderSummary!.items
            .map((item) => {
                  'ingredient_id': item.id,
                  'stall_id': item.shopId,
                })
            .toList();

        if (selectedItems.isEmpty) {
          throw Exception('Không có sản phẩm nào được chọn để thanh toán');
        }

        // Với Mua ngay, đảm bảo item đã có trong giỏ trước khi checkout
        if (_isBuyNow) {
          final cartApiService = CartApiService();
          for (final item in _orderSummary!.items) {
            await cartApiService.addToCart(
              maNguyenLieu: item.id,
              maGianHang: item.shopId,
              soLuong: item.quantity.toDouble(),
            );
          }
        }

        // Lấy thông tin người nhận từ user profile
        final userProfileService = UserProfileService();
        String userName = _orderSummary!.customerName;
        // Ưu tiên số điện thoại từ order summary, fallback sau khi chuẩn hóa
        String phoneNumber =
            _normalizePhoneNumber(_orderSummary?.phoneNumber ?? '');
        if (phoneNumber.isEmpty) {
          phoneNumber = '0912345678'; // fallback an toàn
        }
        // Ưu tiên địa chỉ user đã thay đổi trên trang thanh toán
        String address = _orderSummary!.deliveryAddress;

        try {
          final profileResponse = await userProfileService.getProfile();
          final profile = profileResponse.data;

          // Lấy tên từ profile
          if (profile.tenNguoiDung.isNotEmpty) {
            userName = profile.tenNguoiDung;
          }

          // Lấy số điện thoại từ profile
          if (profile.sdt != null && profile.sdt!.isNotEmpty) {
            final normalized = _normalizePhoneNumber(profile.sdt!);
            if (normalized.isNotEmpty) {
              phoneNumber = normalized;
            }
          }

          // KHÔNG ghi đè address từ profile nữa
          // Giữ nguyên address mà user đã chọn trên trang thanh toán

          if (AppConfig.enableApiLogging) {
            AppLogger.info('👤 [PAYMENT] User profile loaded');
            AppLogger.info('👤 [PAYMENT] Name: $userName');
            AppLogger.info('👤 [PAYMENT] Phone: $phoneNumber');
            AppLogger.info('👤 [PAYMENT] Address (from order): $address');
          }
        } catch (e) {
          if (AppConfig.enableApiLogging) {
            AppLogger.warning(
                '⚠️ [PAYMENT] Could not load user profile, using defaults: $e');
          }
        }

        // Đảm bảo số điện thoại cuối cùng hợp lệ, nếu không fallback mặc định
        if (_normalizePhoneNumber(phoneNumber).isEmpty) {
          if (AppConfig.enableApiLogging) {
            AppLogger.warning(
                '⚠️ [PAYMENT] Invalid phone after normalization, using fallback');
          }
          phoneNumber = '0912345678';
        }

        // Loại bỏ đuôi ', Việt Nam' / ', Vietnam' để backend ghi nhận được
        address = _cleanAddressForBackend(address);

        final recipient = {
          'name': userName,
          'phone': phoneNumber,
          'address': address,
          'notes': _orderSummary?.notes ?? '',
        };

        if (AppConfig.enableApiLogging) {
          AppLogger.info('💳 [PAYMENT] Selected items: $selectedItems');
          AppLogger.info('💳 [PAYMENT] Recipient: $recipient');
        }

        // Gọi API checkout với payment_method = 'tien_mat'
        final currentState = state;
        final cartApiService = CartApiService();
        final checkoutResponse = await cartApiService.checkout(
          selectedItems: selectedItems,
          paymentMethod: 'tien_mat',
          recipient: recipient,
          deliveryAddress: address,
          timeSlotId: currentState is PaymentLoaded ? currentState.timeSlotId : 'KG10',
        );

        if (isClosed) return;

        if (AppConfig.enableApiLogging) {
          AppLogger.info('📦 [PAYMENT] Checkout response:');
          AppLogger.info('   success: ${checkoutResponse.success}');
          AppLogger.info('   maDonHang: "${checkoutResponse.maDonHang}"');
          AppLogger.info('   maThanhToan: "${checkoutResponse.maThanhToan}"');
          AppLogger.info('   tongTien: ${checkoutResponse.tongTien}');
        }

        if (!checkoutResponse.success || checkoutResponse.maDonHang.isEmpty) {
          throw Exception('Checkout failed: Không nhận được mã đơn hàng');
        }

        final orderId = checkoutResponse.maDonHang;
        _maDonHang = orderId;

        if (AppConfig.enableApiLogging) {
          AppLogger.info('🎉 [PAYMENT] Đặt hàng COD thành công!');
          AppLogger.info('📝 [PAYMENT] Mã đơn hàng: $orderId');
          AppLogger.info('💰 [PAYMENT] Tổng tiền: ${checkoutResponse.tongTien}');
        }

        emit(PaymentSuccess(
          message: 'Đặt hàng thành công! Thanh toán khi nhận hàng.',
          orderId: orderId,
        ));
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [PAYMENT] Lỗi khi xử lý thanh toán: ${e.toString()}');
      }
      if (!isClosed) {
        emit(PaymentFailure(
          errorMessage: 'Không thể xử lý thanh toán: ${e.toString()}',
        ));
      }
    }
  }

  /// Get phương thức thanh toán đã chọn
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  /// Get tên phương thức thanh toán
  String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Thanh toán khi giao';
      case PaymentMethod.vnpay:
        return 'VNpay';
    }
  }

  /// Generate mock order summary
  OrderSummary _generateMockOrderSummary() {
    return const OrderSummary(
      customerName: 'Phạm Thị Quỳnh Như',
      phoneNumber: '(+84) 03******12',
      deliveryAddress: '123 Đa Mặn, Mỹ An, Ngũ Hành Sơn, Đà Nẵng, Việt Nam',
      estimatedDelivery: 'Nhận vào 2 giờ tới',
      items: [
        OrderItem(
          id: '1',
          shopName: 'Cô Nhi',
          productName: 'Thịt đùi',
          productImage: 'assets/img/payment_product.png',
          price: 89000,
          weight: 0.7,
          unit: 'KG',
          quantity: 1,
        ),
      ],
      subtotal: 89000,
      total: 104000,
    );
  }

  /// Reset state về initial
  void resetState() {
    _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
    _orderSummary = null;
    emit(PaymentInitial());
  }

  /// Lấy thông tin user từ /auth/me và gắn vào order summary
  Future<OrderSummary> _attachUserInfo(OrderSummary order) async {
    try {
      final profileResponse = await UserProfileService().getProfile();
      final profile = profileResponse.data;

      final name = profile.tenNguoiDung.isNotEmpty
          ? profile.tenNguoiDung
          : order.customerName;

      final phoneRaw = profile.sdt ?? order.phoneNumber;
      final phoneNormalized =
          _normalizePhoneNumber(phoneRaw).isNotEmpty ? _normalizePhoneNumber(phoneRaw) : order.phoneNumber;

      final address = profile.diaChi?.isNotEmpty == true
          ? profile.diaChi!
          : order.deliveryAddress;

      return OrderSummary(
        customerName: name,
        phoneNumber: phoneNormalized,
        deliveryAddress: address,
        estimatedDelivery: order.estimatedDelivery,
        items: order.items,
        subtotal: order.subtotal,
        total: order.total,
      );
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.warning('⚠️ [PAYMENT] Không lấy được thông tin user: $e');
      }
      return order;
    }
  }

  /// Loại bỏ đuôi ', Việt Nam' / ', Vietnam' khỏi địa chỉ
  /// Backend chỉ ghi nhận thay đổi địa chỉ nếu không có đuôi này
  String _cleanAddressForBackend(String address) {
    var cleaned = address.trim();
    
    // Loại bỏ các biến thể đuôi Việt Nam
    final suffixes = [
      ', Việt Nam',
      ', Vietnam',
      ', Viet Nam',
      ',Việt Nam',
      ',Vietnam',
      ',Viet Nam',
    ];
    
    for (final suffix in suffixes) {
      if (cleaned.toLowerCase().endsWith(suffix.toLowerCase())) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length).trim();
        break;
      }
    }
    
    if (AppConfig.enableApiLogging) {
      AppLogger.info('📍 [PAYMENT] Address cleaned: "$address" -> "$cleaned"');
    }
    
    return cleaned;
  }

  /// Chuẩn hóa số điện thoại theo regex /^(0|\+84)\d{9,10}$/
  String _normalizePhoneNumber(String phone) {
    var normalized = phone.trim();
    // Loại bỏ khoảng trắng, dấu, giữ lại số và +
    normalized = normalized.replaceAll(RegExp(r'[^\d\+]'), '');

    if (normalized.startsWith('+84')) {
      normalized = '0${normalized.substring(3)}';
    }

    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    // Đảm bảo độ dài 10-11 chữ số
    if (normalized.length < 10 || normalized.length > 11) {
      return '';
    }

    return normalized;
  }
}
