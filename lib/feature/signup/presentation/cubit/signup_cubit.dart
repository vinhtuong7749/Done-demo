import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/error/app_exception.dart';

part 'signup_state.dart';

/// SignUp Cubit quản lý logic nghiệp vụ của màn hình đăng ký
/// 
/// Chức năng chính:
/// - Xử lý đăng ký với email (username), mật khẩu và tên người dùng
/// - Validate input
/// - Quản lý trạng thái hiển thị mật khẩu
/// - Xử lý lỗi và hiển thị thông báo
class SignUpCubit extends Cubit<SignUpState> {
  final AuthService _authService;

  SignUpCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(SignUpInitial());

  bool _isPasswordVisible = false;
  String _selectedRole = 'nguoi_mua';

  bool get isPasswordVisible => _isPasswordVisible;
  String get selectedRole => _selectedRole;

  /// Cập nhật vai trò
  void setRole(String role) {
    _selectedRole = role;
    emit(SignUpRoleChanged(role: _selectedRole));
  }

  /// Toggle hiển thị/ẩn mật khẩu
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    emit(SignUpPasswordVisibilityChanged(isPasswordVisible: _isPasswordVisible));
  }

  /// Validate tên
  String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Vui lòng nhập tên';
    }
    
    if (name.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    
    return null;
  }

  /// Validate số điện thoại
  String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    // Vietnamese phone number regex
    final phoneRegex = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
    
    if (!phoneRegex.hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ';
    }
    
    return null;
  }

  /// Validate email hoặc username
  String? validateEmail(String? input) {
    if (input == null || input.isEmpty) {
      return 'Vui lòng nhập tên đăng nhập hoặc email';
    }
    
    // Cho phép cả username và email
    // Username: ít nhất 3 ký tự, chỉ chứa chữ, số, gạch dưới, dấu chấm
    // Email: phải có @ và domain
    
    if (input.length < 3) {
      return 'Tên đăng nhập phải có ít nhất 3 ký tự';
    }
    
    // Nếu có @, kiểm tra định dạng email
    if (input.contains('@')) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      
      if (!emailRegex.hasMatch(input)) {
        return 'Email không hợp lệ';
      }
    } else {
      // Nếu không có @, kiểm tra định dạng username
      final usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
      
      if (!usernameRegex.hasMatch(input)) {
        return 'Tên đăng nhập chỉ chứa chữ, số, dấu chấm và gạch dưới';
      }
    }
    
    return null;
  }

  /// Validate password
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    
    return null;
  }

  /// Validate nhập lại mật khẩu
  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }
    
    if (password != confirmPassword) {
      return 'Mật khẩu nhập lại không khớp';
    }
    
    return null;
  }

  /// Xử lý đăng ký
  /// 
  /// Tham số:
  /// - username: Tên đăng nhập (email)
  /// - password: Mật khẩu
  /// - fullName: Tên đầy đủ của người dùng
  /// - phone: Số điện thoại
  /// - role: Vai trò (mặc định: 'nguoi_mua')
  Future<bool> signUp({
    required String username,
    required String password,
    required String confirmPassword,
    required String fullName,
    String phone = '',
    String? role,
  }) async {
    final finalRole = role ?? _selectedRole;
    
    // Validate inputs
    final usernameError = validateEmail(username);
    final passwordError = validatePassword(password);
    final confirmPasswordError = validateConfirmPassword(password, confirmPassword);
    final nameError = validateName(fullName);

    if (usernameError != null || passwordError != null || confirmPasswordError != null || nameError != null) {
      emit(SignUpValidationError(
        nameError: nameError,
        phoneError: null,
        emailError: usernameError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
      ));
      return false;
    }

    try {
      emit(SignUpLoading());

      // Gọi API đăng ký
      final response = await _authService.register(
        username: username,
        password: password,
        fullName: fullName,
        role: finalRole,
        sdt: phone.isNotEmpty ? phone : '0000000000',
      );

      // Check if cubit is still open before emitting success
      if (!isClosed) {
        // Đăng ký thành công
        emit(SignUpSuccess(
          message: 'Đăng ký thành công! Chào mừng ${response.data.tenDangNhap}',
        ));
      }
      
      return true;
    } on ConflictException catch (e) {
      // Username đã tồn tại
      if (!isClosed) {
        emit(SignUpFailure(errorMessage: e.message));
      }
      return false;
    } on ValidationException catch (e) {
      // Dữ liệu không hợp lệ
      if (!isClosed) {
        emit(SignUpFailure(errorMessage: e.message));
      }
      return false;
    } on NetworkException catch (e) {
      // Lỗi mạng
      if (!isClosed) {
        emit(SignUpFailure(errorMessage: e.message));
      }
      return false;
    } on ServerException catch (e) {
      // Lỗi server
      if (!isClosed) {
        emit(SignUpFailure(errorMessage: e.message));
      }
      return false;
    } catch (e) {
      // Lỗi không xác định
      if (!isClosed) {
        emit(SignUpFailure(
          errorMessage: 'Đã có lỗi xảy ra: ${e.toString()}',
        ));
      }
      return false;
    }
  }

  /// Reset state về initial
  void resetState() {
    emit(SignUpInitial());
  }
}
