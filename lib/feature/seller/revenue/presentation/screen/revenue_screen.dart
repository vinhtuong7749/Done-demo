import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/revenue_cubit.dart';
import '../cubit/revenue_state.dart';

class SellerRevenueScreen extends StatelessWidget {
  const SellerRevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerRevenueCubit(),
      child: const SellerRevenueView(),
    );
  }
}

class SellerRevenueView extends StatelessWidget {
  const SellerRevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thống kê doanh thu',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SellerRevenueCubit, SellerRevenueState>(
        builder: (context, state) {
          debugPrint('🖥️ [REVENUE_VIEW] Building with state: isLoading=${state.isLoading}, error=${state.errorMessage}, revenue=${state.paidBalance}');
          if (state.isLoading) {
            return const BuyerLoading(
              message: 'Đang tải dữ liệu doanh thu...',
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerRevenueCubit>().loadRevenue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SellerRevenueCubit>().loadRevenue(),
            color: const Color(0xFFF97316),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterTabs(context, state),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(context, state),
                  const SizedBox(height: 20),
                  _buildMainRevenueCard(state),
                  const SizedBox(height: 24),
                  _buildTrendChart(state),
                  const SizedBox(height: 24),
                  _buildStatsRow(state),
                  const SizedBox(height: 24),
                  _buildBestSellingSection(state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, SellerRevenueState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildTabItem(context, 'Ngày', DateFilter.today, state.selectedDateFilter),
          _buildTabItem(context, 'Tuần', DateFilter.week, state.selectedDateFilter),
          _buildTabItem(context, 'Tháng', DateFilter.month, state.selectedDateFilter),
          _buildTabItem(context, 'Năm', DateFilter.year, state.selectedDateFilter),
          _buildTabItem(context, 'Tùy chỉnh', DateFilter.custom, state.selectedDateFilter),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, String label, DateFilter filter, DateFilter selected) {
    final isActive = filter == selected;
    return GestureDetector(
      onTap: () {
        if (filter == DateFilter.custom) {
          _showDateRangePicker(context);
        } else {
          context.read<SellerRevenueCubit>().selectDateFilter(filter);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFFF97316) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, SellerRevenueState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    String dateRangeText = '';

    final now = DateTime.now();
    if (state.selectedDateFilter == DateFilter.today) {
      dateRangeText = dateFormat.format(now);
    } else if (state.selectedDateFilter == DateFilter.week) {
      final start = now.subtract(const Duration(days: 7));
      dateRangeText = '${dateFormat.format(start)} - ${dateFormat.format(now)}';
    } else if (state.selectedDateFilter == DateFilter.month) {
      final start = DateTime(now.year, now.month, 1);
      dateRangeText = '${dateFormat.format(start)} - ${dateFormat.format(now)}';
    } else if (state.selectedDateFilter == DateFilter.year) {
      dateRangeText = 'Năm ${now.year}';
    } else {
      dateRangeText = state.customStartDate != null && state.customEndDate != null
          ? '${dateFormat.format(state.customStartDate!)} - ${dateFormat.format(state.customEndDate!)}'
          : 'Chọn khoảng thời gian';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 22, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              dateRangeText,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 24, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildMainRevenueCard(SellerRevenueState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.payments_outlined,
              size: 100,
              color: const Color(0xFF22C55E).withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TỔNG DOANH THU',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_formatCurrency(state.paidBalance)}đ',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 20, color: Color(0xFF22C55E)),
                    const SizedBox(width: 8),
                    Text(
                      '${state.revenueChangePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'so với tháng trước',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(SellerRevenueState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Biểu đồ xu hướng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Tính toán độ rộng cần thiết. Mỗi điểm dữ liệu cần khoảng 50px
              final double minWidth = constraints.maxWidth;
              final double dataWidth = state.dailyRevenue.length * 60.0;
              final double chartWidth = dataWidth > minWidth ? dataWidth : minWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: 220,
                  width: chartWidth,
                  child: state.dailyRevenue.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có dữ liệu giao dịch',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : CustomPaint(
                          painter: AreaChartPainter(state.dailyRevenue),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SellerRevenueState state) {
    return Row(
      children: [
        _buildStatCard('ĐƠN HÀNG', state.orderCount.toString()),
        const SizedBox(width: 12),
        _buildStatCard('GIÁ TRỊ TB', '${(state.averageOrderValue / 1000).toStringAsFixed(0)}k'),
        const SizedBox(width: 12),
        _buildStatCard('CHUYỂN ĐỔI', '${state.conversionRate}%'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingSection(SellerRevenueState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sản phẩm bán chạy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tất cả',
                style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...state.bestSellingProducts.map((product) => _buildProductItem(product)),
      ],
    );
  }

  Widget _buildProductItem(BestSellingProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF), size: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.orderCount} đơn hàng',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(product.totalAmount / 1000000).toStringAsFixed(1)}M',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    product.changePercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: product.changePercentage >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${product.changePercentage >= 0 ? '+' : ''}${product.changePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: product.changePercentage >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (context.mounted) {
        context.read<SellerRevenueCubit>().setCustomDateRange(picked.start, picked.end);
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return formatter.format(amount);
  }
}

class AreaChartPainter extends CustomPainter {
  final Map<String, double> data;

  AreaChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final keys = data.keys.toList();
    final values = data.values.toList();

    // Padding trên cùng để vẽ giá trị tiền, padding dưới để vẽ ngày tháng
    final topPadding = 30.0;
    final bottomPadding = 25.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final widthStep = values.length > 1 ? size.width / (values.length - 1) : size.width / 2;

    List<Offset> points = [];

    // Tính toán tọa độ điểm
    for (var i = 0; i < values.length; i++) {
      final x = values.length > 1 ? i * widthStep : size.width / 2;
      final normalizedValue = maxValue > 0 ? (values[i] / maxValue) : 0.0;
      final y = topPadding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Vẽ bóng gradient
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height - bottomPadding);
      for (var p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, size.height - bottomPadding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFB923C).withValues(alpha: 0.4),
            const Color(0xFFFB923C).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // Vẽ đường biểu đồ
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      final paint = Paint()
        ..color = const Color(0xFFF97316)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
        
      canvas.drawPath(path, paint);
    }

    // Vẽ điểm tròn và Text
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pointBorderPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Vẽ vòng tròn
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, pointBorderPaint);

      // Vẽ giá trị (Doanh thu) ngay trên điểm
      final value = values[i];
      final textValue = value >= 1000000 
          ? '${(value / 1000000).toStringAsFixed(1)}M'
          : '${(value / 1000).toStringAsFixed(0)}k';
          
      final valuePainter = TextPainter(
        text: TextSpan(
          text: textValue,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas, 
        Offset(point.dx - valuePainter.width / 2, point.dy - 22)
      );

      // Vẽ Ngày Tháng ở trục X
      String dateStr = keys[i];
      try {
        final date = DateTime.parse(dateStr);
        dateStr = '${date.day}/${date.month}'; // Format DD/MM
      } catch (_) {}

      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      datePainter.layout();
      datePainter.paint(
        canvas, 
        Offset(point.dx - datePainter.width / 2, size.height - datePainter.height)
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
