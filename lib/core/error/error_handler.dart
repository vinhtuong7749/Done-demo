import 'package:flutter/material.dart';
import '../config/route_name.dart';
import '../utils/app_logger.dart';
import 'app_exception.dart';

/// Global error handler
class ErrorHandler {
  ErrorHandler._();

  /// Handle exception and return user-friendly message
  static String handleException(dynamic error) {
    AppLogger.error('Error occurred', error);

    if (error is AppException) {
      return error.message;
    }

    if (error is NetworkException) {
      return error.message;
    }

    if (error is TimeoutException) {
      return error.message;
    }

    if (error is ServerException) {
      return error.message;
    }

    if (error is UnauthorizedException) {
      return error.message;
    }

    if (error is NotFoundException) {
      return error.message;
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is ParseException) {
      return error.message;
    }

    if (error is CacheException) {
      return error.message;
    }

    if (error is PermissionDeniedException) {
      return error.message;
    }

    return 'Đã xảy ra lỗi không xác định';
  }

  /// Show error dialog
  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) {
    final message = handleException(error);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Lỗi'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Thử lại'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(RouteName.main, (route) => false);
            },
            child: const Text('Về trang chủ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = handleException(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Log error for debugging
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('Error: ${handleException(error)}', error, stackTrace);
  }
}
