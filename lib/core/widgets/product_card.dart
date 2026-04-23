import 'package:flutter/material.dart';
import '../config/route_name.dart';

/// Shared Product Card Widget
/// Used in both Product Screen and Product Detail Screen
class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String soldCount;
  final String imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.soldCount,
    required this.imagePath,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
    this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Color(0xFFFF0000),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF0000),
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: Color(0xFF757575),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    soldCount,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF008EDB)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Thêm vào giỏ hàng',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF008EDB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: onBuyNow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Mua ngay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 8,
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
            ),
          ],
        ),
      ),
    );
  }
}
