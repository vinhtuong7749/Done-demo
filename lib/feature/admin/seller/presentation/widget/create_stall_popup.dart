import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/seller_management_cubit.dart';

class CreateStallPopup extends StatefulWidget {
  final String maNguoiDung;
  final String tenNguoiDung;

  const CreateStallPopup({
    super.key,
    required this.maNguoiDung,
    required this.tenNguoiDung,
  });

  @override
  State<CreateStallPopup> createState() => _CreateStallPopupState();
}

class _CreateStallPopupState extends State<CreateStallPopup> {
  final _formKey = GlobalKey<FormState>();
  final _tenGianHangController = TextEditingController();
  final _colController = TextEditingController();
  final _rowController = TextEditingController();

  String _selectedLocation = 'TH'; // Mặc định là Thịt
  bool _isLoading = false;

  final Map<String, String> _locationOptions = {
    'TH': 'Thịt',
    'RC': 'Rau củ',
    'HS': 'Hải sản',
    'GV': 'Gia vị/Tạp hóa',
    'KH': 'Khác',
  };

  @override
  void dispose() {
    _tenGianHangController.dispose();
    _colController.dispose();
    _rowController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<SellerManagementCubit>().createStallForPendingSeller(
          maNguoiDung: widget.maNguoiDung,
          tenGianHang: _tenGianHangController.text.trim(),
          stallLocation: _selectedLocation,
          gridCol: int.tryParse(_colController.text) ?? 0,
          gridRow: int.tryParse(_rowController.text) ?? 0,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo gian hàng thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo gian hàng thất bại! Vui lòng thử lại.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tạo gian hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiểu thương: ${widget.tenNguoiDung}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tenGianHangController,
                  decoration: _inputDecoration('Tên gian hàng (*)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên gian hàng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: _inputDecoration('Loại mặt hàng (*)'),
                  items: _locationOptions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocation = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colController,
                        decoration: _inputDecoration('Tọa độ Cột (Col)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bắt buộc nhập';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Phải là số';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _rowController,
                        decoration: _inputDecoration('Tọa độ Hàng (Row)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bắt buộc nhập';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Phải là số';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F8000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Tạo sạp',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
