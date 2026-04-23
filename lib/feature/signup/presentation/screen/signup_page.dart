import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/signup_cubit.dart';
import '../../../../core/dependency/injection.dart';
import '../../../../core/services/auth/auth_service.dart';

/// Màn hình đăng ký người mua / người bán
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const String routeName = '/signup';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(authService: getIt<AuthService>()),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SignUpCubit, SignUpState>(
        listener: (context, state) {
          if (!mounted) return;
          if (state is SignUpSuccess) {
            final role = context.read<SignUpCubit>().selectedRole;
            final isSeller = role == 'nguoi_ban';

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isSeller ? Icons.store_outlined : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSeller
                          ? 'Đăng ký thành công! Chờ quản lý chợ tạo gian hàng để bắt đầu bán.'
                          : 'Đăng ký thành công! Chào mừng bạn.',
                    ),
                  ),
                ],
              ),
              backgroundColor:
                  isSeller ? const Color(0xFFE65100) : const Color(0xFF2F8000),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        } else if (state is SignUpFailure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.errorMessage)),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75), // Brightens the background
          ),
          child: SafeArea(
            child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildLogo(),
                        const SizedBox(height: 28),
                        _buildCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/img/splash_logo.png',
      width: 160,
      fit: BoxFit.contain,
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEBFAEC).withValues(alpha: 0.95), // Light green tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4FC3F7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header tabs
          _buildHeaderTabs(),
          // Form body
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRoleSelection(),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _nameController,
                    hint: 'Tên',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        context.read<SignUpCubit>().validateName(v),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _phoneController,
                    hint: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        context.read<SignUpCubit>().validatePhone(v),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _usernameController,
                    hint: 'Email/Tên đăng nhập',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        context.read<SignUpCubit>().validateEmail(v),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 8),
                  // Seller notice
                  _buildSellerNotice(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Đăng nhập tab (inactive)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF75B875), // Soft green
              ),
            ),
          ),
          // Đăng ký tab (active)
          Column(
            children: [
              const Text(
                'Đăng ký',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF009C0D), // Dark solid green
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2.5,
                width: 48,
                color: const Color(0xFFE53935), // Red underline
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpRoleChanged,
      builder: (context, state) {
        final selectedRole = context.read<SignUpCubit>().selectedRole;
        return Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: 'nguoi_mua',
                label: 'Người mua',
                icon: Icons.shopping_bag_outlined,
                subtitle: 'Mua sắm tại chợ',
                isSelected: selectedRole == 'nguoi_mua',
                onTap: () =>
                    context.read<SignUpCubit>().setRole('nguoi_mua'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                role: 'nguoi_ban',
                label: 'Người bán',
                icon: Icons.store_outlined,
                subtitle: 'Bán hàng tại chợ',
                isSelected: selectedRole == 'nguoi_ban',
                onTap: () =>
                    context.read<SignUpCubit>().setRole('nguoi_ban'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        label: RichText(
          text: TextSpan(
            text: hint,
            style: const TextStyle(color: Color(0xFF757575), fontSize: 15),
            children: [
              if (isRequired)
                const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF757575), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF00B40F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpPasswordVisibilityChanged,
      builder: (context, state) {
        final visible = context.read<SignUpCubit>().isPasswordVisible;
        return TextFormField(
          controller: _passwordController,
          obscureText: !visible,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            label: RichText(
              text: const TextSpan(
                text: 'Mật khẩu',
                style: TextStyle(color: Color(0xFF757575), fontSize: 15),
                children: [
                  TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            prefixIcon: const Icon(Icons.password_rounded,
                color: Color(0xFF757575), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9E9E9E),
                size: 20,
              ),
              onPressed: () =>
                  context.read<SignUpCubit>().togglePasswordVisibility(),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF00B40F), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: (v) =>
              context.read<SignUpCubit>().validatePassword(v),
        );
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpPasswordVisibilityChanged,
      builder: (context, state) {
        final visible = context.read<SignUpCubit>().isPasswordVisible;
        return TextFormField(
          controller: _confirmPasswordController,
          obscureText: !visible,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            label: RichText(
              text: const TextSpan(
                text: 'Nhập lại mật khẩu',
                style: TextStyle(color: Color(0xFF757575), fontSize: 15),
                children: [
                   TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            prefixIcon: const Icon(Icons.password_rounded,
                color: Color(0xFF757575), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF00B40F), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: (v) => context
              .read<SignUpCubit>()
              .validateConfirmPassword(_passwordController.text, v),
        );
      },
    );
  }

  Widget _buildSellerNotice() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (prev, curr) => curr is SignUpRoleChanged,
      builder: (context, state) {
        final isSeller =
            context.read<SignUpCubit>().selectedRole == 'nguoi_ban';
        if (!isSeller) return const SizedBox.shrink();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.6)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFFE65100), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sau khi đăng ký, tài khoản sẽ được kích hoạt khi Quản lý chợ tạo gian hàng cho bạn.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFBF360C),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        final isLoading = state is SignUpLoading;
        return SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      await context.read<SignUpCubit>().signUp(
                            username: _usernameController.text.trim(),
                            password: _passwordController.text,
                            confirmPassword:
                                _confirmPasswordController.text,
                            fullName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C800), // Bright green like in mockup
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Bạn đã có tài khoản? ',
            style: TextStyle(fontSize: 14, color: Color(0xFF1E1E1E), fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00C800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F5E9)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C800)
                : const Color(0xFF4FC3F7),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2F8000)
                    : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF2F8000)
                    : const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

