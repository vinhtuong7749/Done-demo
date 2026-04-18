import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dngo/core/config/route_name.dart';
import 'package:dngo/core/models/generated_menu_models.dart';

class MenuDetailScreen extends StatefulWidget {
  const MenuDetailScreen({super.key});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  static const Color _accent = Color(0xFF16A34A);
  static const Color _accentDark = Color(0xFF166534);

  final PageController _pageController = PageController();
  int _currentDayIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan =
        ModalRoute.of(context)?.settings.arguments as SavedMenuCollection?;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết thực đơn')),
        body: const Center(
          child: Text('Không tìm thấy dữ liệu thực đơn để hiển thị'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Chi tiết bữa ăn theo từng ngày',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(plan),
          _buildDayTabs(plan),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Các bữa ăn trong ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: plan.menu.length,
              onPageChanged: (index) {
                setState(() {
                  _currentDayIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final dayPlan = plan.menu[index];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Ngày ${dayPlan.day} • ${dayPlan.meals.length} bữa được gợi ý',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    ...dayPlan.meals.map(_buildMealCard),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SavedMenuCollection plan) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FCEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.healthGoal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _accentDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lưu lúc ${formatter.format(plan.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryStat('Số ngày', '${plan.days}')),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryStat('Bữa/ngày', '${plan.mealsPerDay}'),
              ),
            ],
          ),
          if (plan.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.notes
                  .map(
                    (note) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(SavedMenuCollection plan) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: plan.menu.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _currentDayIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? _accent : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                'Ngày ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard(MenuMealPlan meal) {
    final mealColor = _mealColor(meal.meal);
    final mealIcon = _mealIcon(meal.meal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (meal.dish.dishId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Món này chưa có mã chi tiết để mở'),
                ),
              );
              return;
            }

            Navigator.pushNamed(
              context,
              RouteName.productDetail,
              arguments: meal.dish.dishId,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child:
                            meal.dish.imageUrl != null &&
                                meal.dish.imageUrl!.isNotEmpty
                            ? Image.network(
                                meal.dish.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(mealColor);
                                },
                              )
                            : _buildImagePlaceholder(mealColor),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: mealColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          meal.meal,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(mealIcon, size: 16, color: mealColor),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Bữa ăn được đề xuất',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meal.dish.dishName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (meal.dish.calories != null)
                            _buildMetaChip(
                              '🔥 ${meal.dish.calories!.round()} kcal',
                            ),
                          if (meal.dish.cookingTime != null &&
                              meal.dish.cookingTime!.isNotEmpty)
                            _buildMetaChip('⏱ ${meal.dish.cookingTime!}'),
                          if (meal.dish.level != null &&
                              meal.dish.level!.isNotEmpty)
                            _buildMetaChip('📊 ${meal.dish.level!}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Xem chi tiết món',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mealColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: mealColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.restaurant_rounded, color: color, size: 34),
    );
  }

  IconData _mealIcon(String meal) {
    final lower = meal.toLowerCase();
    if (lower.contains('sáng')) return Icons.wb_sunny_outlined;
    if (lower.contains('trưa')) return Icons.sunny_snowing;
    if (lower.contains('tối')) return Icons.nightlight_round;
    return Icons.restaurant_rounded;
  }

  Color _mealColor(String meal) {
    final lower = meal.toLowerCase();
    if (lower.contains('sáng')) return const Color(0xFFF59E0B);
    if (lower.contains('trưa')) return const Color(0xFF16A34A);
    if (lower.contains('tối')) return const Color(0xFF6366F1);
    return _accent;
  }
}
