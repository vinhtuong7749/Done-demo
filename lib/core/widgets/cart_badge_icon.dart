import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/cart_api_service.dart';
import '../../feature/buyer/cart/presentation/screen/cart_page.dart';

/// Stream controller để refresh cart badge từ bất kỳ đâu
final StreamController<void> _cartRefreshController = StreamController<void>.broadcast();

/// Helper function để refresh cart badge từ bất kỳ đâu
void refreshCartBadge() {
  _cartRefreshController.add(null);
}

/// Widget icon giỏ hàng với badge hiển thị số lượng sản phẩm
/// Tự động fetch từ API và cập nhật
class CartBadgeIcon extends StatefulWidget {
  final double iconSize;
  final Color? iconColor;
  final TextStyle? badgeTextStyle;
  final Color? badgeBackgroundColor;

  const CartBadgeIcon({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.badgeTextStyle,
    this.badgeBackgroundColor,
  });

  @override
  State<CartBadgeIcon> createState() => _CartBadgeIconState();
}

class _CartBadgeIconState extends State<CartBadgeIcon> {
  final CartApiService _cartService = CartApiService();
  int _itemCount = 0;
  bool _isLoading = false;
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _refreshSubscription = _cartRefreshController.stream.listen((_) {
      _loadCartCount();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final cartResponse = await _cartService.getCart();
      if (mounted) {
        setState(() {
          _itemCount = cartResponse.cart.soMatHang;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _itemCount = 0; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: SvgPicture.asset(
              'assets/img/add_shopping_cart.svg',
              width: widget.iconSize,
              height: widget.iconSize,
              colorFilter: widget.iconColor != null ? ColorFilter.mode(widget.iconColor!, BlendMode.srcIn) : const ColorFilter.mode(Color(0xFF333333), BlendMode.srcIn),
            ),
          ),
          if (_itemCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeBackgroundColor ?? const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    _itemCount > 99 ? '99+' : _itemCount.toString(),
                    style: widget.badgeTextStyle ?? const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.badgeBackgroundColor ?? const Color(0xFFFF3B30), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))),
              ),
            ),
        ],
      ),
    );
  }
}
