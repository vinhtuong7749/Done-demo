import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dngo/core/config/route_name.dart';
import 'package:dngo/core/dependency/injection.dart';
import 'package:dngo/core/models/generated_menu_models.dart';
import 'package:dngo/core/services/llm_chatbot_service.dart';
import 'package:dngo/core/services/local_storage_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with AutomaticKeepAliveClientMixin {
  final LlmChatbotService _llmService = getIt<LlmChatbotService>();
  final LocalStorageService _storage = getIt<LocalStorageService>();

  static const Color _accent = Color(0xFF16A34A);
  static const Color _accentDark = Color(0xFF166534);

  static const List<String> _goals = [
    'Cân bằng',
    'Giảm cân',
    'Tăng cân',
    'Tăng cơ',
    'Sức đề kháng',
  ];

  static const List<String> _notes = [
    'Món chay',
    'Ăn kiêng',
    'Miền Bắc',
    'Miền Trung',
    'Miền Nam',
    'Người lớn tuổi',
  ];

  final Set<String> _selectedNotes = <String>{};
  List<SavedMenuCollection> _savedMenus = const [];
  String _selectedGoal = _goals.first;
  int _selectedDays = 3;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedMenus();
  }

  void _loadSavedMenus() {
    if (!mounted) return;
    setState(() {
      _savedMenus = _storage.getSavedMenuPlans();
    });
  }

  Future<void> _generateMenu() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final generated = await _llmService.generateMenu(
        days: _selectedDays,
        mealsPerDay: 3,
        healthGoal: _selectedGoal,
        notes: _selectedNotes.toList(),
      );

      final updatedMenus = [generated, ..._storage.getSavedMenuPlans()];
      await _storage.saveMenuPlans(updatedMenus);

      if (!mounted) return;

      setState(() {
        _savedMenus = updatedMenus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo và lưu thực đơn thành công')),
      );

      Navigator.pushNamed(context, RouteName.menuDetail, arguments: generated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo thực đơn: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMenu(String localId) async {
    await _storage.deleteSavedMenuPlan(localId);
    _loadSavedMenus();
  }

  String _buildPreviewText(SavedMenuCollection plan) {
    if (plan.menu.isEmpty) {
      return 'Chưa có dữ liệu món ăn để hiển thị.';
    }

    final meals = plan.menu.first.meals
        .map((item) => item.dish.dishName)
        .where((name) => name.isNotEmpty)
        .take(3)
        .join(' • ');

    if (meals.isEmpty) {
      return 'Ngày đầu tiên chưa có món cụ thể.';
    }

    return 'Ngày 1: $meals';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadSavedMenus();
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _buildGeneratorCard(),
              const SizedBox(height: 20),
              _buildSavedSectionHeader(),
              const SizedBox(height: 12),
              if (_savedMenus.isEmpty) _buildEmptyState(),
              ..._savedMenus.map(_buildSavedMenuCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorCard() {
    return Container(
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
                child: const Icon(Icons.tune_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo thực đơn mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Chọn nhu cầu và hệ thống sẽ gợi ý bữa ăn phù hợp.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mục tiêu sức khỏe',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedGoal,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            items: _goals
                .map(
                  (goal) =>
                      DropdownMenuItem<String>(value: goal, child: Text(goal)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedGoal = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Số ngày lên thực đơn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 3, 5, 7].map((days) {
              final isSelected = _selectedDays == days;
              return _buildOptionChip(
                label: '$days ngày',
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedDays = days;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tùy chọn thêm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _notes.map((note) {
              final isSelected = _selectedNotes.contains(note);
              return _buildOptionChip(
                label: note,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedNotes.remove(note);
                    } else {
                      _selectedNotes.add(note);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _accent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thực đơn được lưu tự động trên máy sau khi tạo.',
                    style: TextStyle(fontSize: 12, color: _accentDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateMenu,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isLoading ? 'Đang tạo thực đơn...' : 'Tạo và lưu thực đơn',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9FCEB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _accentDark : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Menu đã lưu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            '${_savedMenus.length} mục',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 46, color: Color(0xFF9CA3AF)),
          SizedBox(height: 12),
          Text(
            'Chưa có thực đơn nào được lưu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy tạo một thực đơn mới để bắt đầu lên kế hoạch bữa ăn trong ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMenuCard(SavedMenuCollection plan) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushNamed(context, RouteName.menuDetail, arguments: plan);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9FCEB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 3),
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
                    IconButton(
                      onPressed: () => _deleteMenu(plan.localId),
                      icon: const Icon(Icons.delete_outline_rounded),
                      splashRadius: 18,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMenuInfoPill(
                      Icons.local_fire_department_outlined,
                      plan.healthGoal,
                    ),
                    _buildMenuInfoPill(
                      Icons.calendar_month_outlined,
                      '${plan.days} ngày',
                    ),
                    _buildMenuInfoPill(
                      Icons.restaurant_outlined,
                      '${plan.mealsPerDay} bữa/ngày',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _buildPreviewText(plan),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                  ),
                ),
                if (plan.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Xem chi tiết thực đơn',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _accentDark,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _accentDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
