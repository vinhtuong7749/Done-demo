import 'package:flutter/material.dart';
import '../../../feature/buyer/home/presentation/cubit/home_state.dart';

/// Widget hiển thị card gian hàng suggestion từ AI
class GianHangSuggestionCard extends StatelessWidget {
  final GianHangSuggestion gianHang;
  final VoidCallback onTap;

  const GianHangSuggestionCard({
    super.key,
    required this.gianHang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với hình ảnh gian hàng
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: gianHang.hinhAnh != null && gianHang.hinhAnh!.isNotEmpty
                  ? Image.network(
                      gianHang.hinhAnh!,
                      width: 280,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildLoadingImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên gian hàng
                  Text(
                    gianHang.tenGianHang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rating và vị trí
                  Row(
                    children: [
                      if (gianHang.rating > 0) ...[
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text(
                          gianHang.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF666666)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          gianHang.viTri,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Danh sách hàng hóa (tối đa 3 items)
                  ...gianHang.hangHoa.take(3).map((hangHoa) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        // Hình ảnh hàng hóa
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: hangHoa.hinhAnh != null && hangHoa.hinhAnh!.isNotEmpty
                              ? Image.network(
                                  hangHoa.hinhAnh!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildSmallPlaceholder();
                                  },
                                )
                              : _buildSmallPlaceholder(),
                        ),
                        const SizedBox(width: 8),

                        // Thông tin hàng hóa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hangHoa.tenNguyenLieu,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              Text(
                                '${_formatPrice(hangHoa.gia)}/${hangHoa.donVi}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Color(0xFF0272BA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

                  // Hiển thị số lượng hàng còn lại nếu có
                  if (gianHang.tongSoHang > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${gianHang.tongSoHang - 3} sản phẩm khác',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 280,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.store, size: 48, color: Colors.grey),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 280,
      height: 120,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[300],
      child: const Icon(Icons.food_bank, size: 20, color: Colors.grey),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return price.toStringAsFixed(0);
  }
}
