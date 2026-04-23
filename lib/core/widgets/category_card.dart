import 'package:flutter/material.dart';

/// Category Card Widget
/// Hiển thị danh mục với icon/ảnh và tên
class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B40F) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00B40F).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ),
      ),
    );
  }
}
