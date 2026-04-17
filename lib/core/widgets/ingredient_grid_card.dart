import 'package:flutter/material.dart';

/// Ingredient Grid Card Widget
/// Card nguyên liệu dạng vuông cho grid layout
class IngredientGridCard extends StatelessWidget {
  final String name;
  final String? price;
  final String? imagePath;
  final String? shopName;
  final bool isShopOpen; // Trạng thái gian hàng
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const IngredientGridCard({
    super.key,
    required this.name,
    this.price,
    this.imagePath,
    this.shopName,
    this.isShopOpen = true,
    this.onTap,
    this.onAddToCart,
    this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isShopOpen ? 1 : 0.58,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(flex: 3, child: _buildImageSection()),

              // Info Section
              Expanded(flex: 2, child: _buildInfoSection()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final isNetworkImage =
        imagePath != null &&
        (imagePath!.startsWith('http://') || imagePath!.startsWith('https://'));

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: imagePath != null && imagePath!.isNotEmpty
              ? (isNetworkImage
                    ? Image.network(
                        imagePath!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFF00B40F),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : Image.asset(
                        imagePath!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ))
              : _buildPlaceholder(),
        ),
        if (!isShopOpen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HẾT HÀNG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00B40F).withValues(alpha: 0.05),
            const Color(0xFF008EDB).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 32,
        color: Color(0xFF8E8E93),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 2),

          // Shop Name
          if (shopName != null && shopName!.isNotEmpty)
            Text(
              shopName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          const SizedBox(height: 4),

          // Price
          if (price != null && price!.isNotEmpty)
            Text(
              price!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF3B30),
              ),
            ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isShopOpen ? onAddToCart : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isShopOpen
                            ? const Color(0xFF008EDB)
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: isShopOpen ? Colors.transparent : Colors.grey[100],
                    ),
                    child: Text(
                      'Thêm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isShopOpen
                            ? const Color(0xFF008EDB)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: isShopOpen ? onBuyNow : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isShopOpen ? const Color(0xFF00B40F) : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mua',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
