import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/wallet_model.dart';
import 'package:intl/intl.dart';

class WithdrawalDialog extends StatefulWidget {
  final int availableBalance;
  final String? defaultBankAccount;
  final String? defaultBankName;
  final String? defaultAccountName; // Often we don't have account name, so we let them enter if missing
  final Function(WithdrawRequest) onSubmit;

  const WithdrawalDialog({
    super.key,
    required this.availableBalance,
    this.defaultBankAccount,
    this.defaultBankName,
    this.defaultAccountName,
    required this.onSubmit,
  });

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  late TextEditingController _amountController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _accountNameController;

  final _formKey = GlobalKey<FormState>();
  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '');

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _bankNameController = TextEditingController(text: widget.defaultBankName ?? '');
    _bankAccountController = TextEditingController(text: widget.defaultBankAccount ?? '');
    _accountNameController = TextEditingController(text: widget.defaultAccountName ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rút tiền',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Available Balance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khả dụng',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        Text(
                          '${formatCurrency.format(widget.availableBalance)} đ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Số tiền rút (VNĐ)'),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF9CA3AF)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) return 'Số tiền phải lớn hơn 0';
                  if (amount > widget.availableBalance) return 'Số dư không đủ';
                  if (amount < 50000) return 'Tối thiểu 50.000 đ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Ngân hàng'),
              TextFormField(
                controller: _bankNameController,
                decoration: _inputDecoration('VD: Vietcombank, MBBank...'),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên ngân hàng' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Sô tài khoản'),
              TextFormField(
                controller: _bankAccountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Nhập số tài khoản'),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Tên chủ tài khoản'),
              TextFormField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('VD: NGUYEN VAN A'),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên chủ tài khoản' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final amount = int.parse(_amountController.text);
                      final request = WithdrawRequest(
                        amount: amount,
                        bankBin: _bankNameController.text.trim(),
                        bankAccountNo: _bankAccountController.text.trim(),
                        accountName: _accountNameController.text.trim().toUpperCase(),
                      );
                      widget.onSubmit(request);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận rút tiền',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
