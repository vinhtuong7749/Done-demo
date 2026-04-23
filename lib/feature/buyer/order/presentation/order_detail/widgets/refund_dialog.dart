import 'package:flutter/material.dart';
import '../../../../../../core/services/order_service.dart';

class RefundDialog extends StatefulWidget {
  final String orderId;
  final List<OrderItemDetail> eligibleItems;
  final Function(List<RefundItem>) onConfirm;

  const RefundDialog({
    super.key,
    required this.orderId,
    required this.eligibleItems,
    required this.onConfirm,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  final List<String> _validReasons = const [
    "Hàng hóa đổ bể",
    "Giao hàng trễ",
    "Sản phẩm không giống mô tả",
    "Chất lượng sản phẩm kém",
    "Thiếu sản phẩm",
    "Không còn nhu cầu mua hàng"
  ];

  late String _selectedReason;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _selectedReason = _validReasons.first;
    // Default selecting all eligible items
    for (var i = 0; i < widget.eligibleItems.length; i++) {
      _selectedItems.add(widget.eligibleItems[i].maNguyenLieu + "_" + widget.eligibleItems[i].maGianHang);
    }
  }

  void _submit() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 sản phẩm để hoàn tiền'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final refundItems = widget.eligibleItems
        .where((item) => _selectedItems.contains(item.maNguyenLieu + "_" + item.maGianHang))
        .map((item) => RefundItem(
              ingredientId: item.maNguyenLieu,
              stallId: item.maGianHang,
              reason: _selectedReason,
            ))
        .toList();

    widget.onConfirm(refundItems);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yêu Cầu Hoàn Tiền',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF202020),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn sản phẩm cần hoàn:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.eligibleItems.length,
                itemBuilder: (context, index) {
                  final item = widget.eligibleItems[index];
                  final uniqueId = item.maNguyenLieu + "_" + item.maGianHang;
                  final isSelected = _selectedItems.contains(uniqueId);

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedItems.add(uniqueId);
                        } else {
                          _selectedItems.remove(uniqueId);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item.nguyenLieu?.hinhAnh != null)
                              ? Image.network(
                                  item.nguyenLieu!.hinhAnh!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nguyenLieu?.tenNguyenLieu ?? 'Sản phẩm',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.soLuong} x ${item.giaCuoi.toInt()}đ',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lý do hoàn tiền:',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedReason,
                  items: _validReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedReason = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F8000),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Xác Nhận Yêu Cầu',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey, size: 20),
    );
  }
}
