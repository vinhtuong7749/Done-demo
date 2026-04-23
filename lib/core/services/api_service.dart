import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../models/network_response.dart';
import '../utils/app_logger.dart';
import 'network_interceptor.dart';
import 'local_storage_service.dart';

/// Service để gọi API sử dụng Dio
class ApiService {
  static const String baseUrl = 'http://207.180.233.84:8000';
  static const String coreBaseUrl = 'http://207.180.233.84:8000';
  static const String chatbotBaseUrl = 'https://chat-api.dangtiensinh.workers.dev';

  late final Dio _dio;
  final LocalStorageService _localStorageService;

  ApiService(this._localStorageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConfig.sendTimeout),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptor
    _dio.interceptors.add(NetworkInterceptor(_localStorageService));

    // Add logging interceptor in debug mode
    if (AppConfig.instance.isDevelopment) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// GET request
  Future<NetworkResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('GET request error', e);
      throw AppException(message: 'Đã xảy ra lỗi: $e');
    }
  }

  /// POST request
  Future<NetworkResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('POST request error', e);
      throw AppException(message: 'Đã xảy ra lỗi: $e');
    }
  }

  /// PUT request
  Future<NetworkResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('PUT request error', e);
      throw AppException(message: 'Đã xảy ra lỗi: $e');
    }
  }

  /// PATCH request
  Future<NetworkResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('PATCH request error', e);
      throw AppException(message: 'Đã xảy ra lỗi: $e');
    }
  }

  /// DELETE request
  Future<NetworkResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('DELETE request error', e);
      throw AppException(message: 'Đã xảy ra lỗi: $e');
    }
  }

  /// Upload file
  Future<NetworkResponse<T>> uploadFile<T>(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('Upload file error', e);
      throw AppException(message: 'Đã xảy ra lỗi khi upload file: $e');
    }
  }

  /// Download file
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error('Download file error', e);
      throw AppException(message: 'Đã xảy ra lỗi khi download file: $e');
    }
  }

  /// Handle response
  NetworkResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      // Success
      final data = response.data;
      
      if (fromJson != null && data != null) {
        try {
          return NetworkResponse.success(fromJson(data));
        } catch (e) {
          AppLogger.error('JSON parsing error', e);
          throw AppException(message: 'Lỗi xử lý dữ liệu');
        }
      }

      return NetworkResponse.success(data as T);
    } else {
      // Error
      final message = _extractErrorMessage(response.data);
      throw AppException(
        message: message,
        statusCode: statusCode,
      );
    }
  }

  /// Handle Dio error
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _extractErrorMessage(error.response?.data);
        
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        } else if (statusCode == 404) {
          return NotFoundException(message: message);
        } else {
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
        }
      
      case DioExceptionType.connectionError:
        return NetworkException();
      
      case DioExceptionType.cancel:
        return AppException(message: 'Yêu cầu đã bị hủy');
      
      default:
        return AppException(
          message: error.message ?? 'Đã xảy ra lỗi không xác định',
        );
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Đã xảy ra lỗi';
    
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 
             data['error'] as String? ?? 
             'Đã xảy ra lỗi';
    }
    
    return data.toString();
  }
}
