/// Cấu hình toàn cục cho ứng dụng DNGO - Đi Chợ Online
/// Chứa các thông tin về môi trường, API, timeout, etc.
class AppConfig {
  // Singleton pattern
  AppConfig._();
  static final AppConfig instance = AppConfig._();
  factory AppConfig() => instance;

  // Environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  // --- API Configuration (Cập nhật sang DNGO) ---
  // Base URL chính (mặc định local)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // Standalone LLM chatbot API (khong di qua DNGO-fastapi)
  static const String llmBaseUrl = String.fromEnvironment(
    'LLM_BASE_URL',
    defaultValue: 'http://127.0.0.1:8001',
  );
  static const String llmChatEndpoint = '/chat';

  // WebSocket endpoint cho chat buyer-seller realtime
  static const String chatWebSocketBaseUrl = String.fromEnvironment(
    'CHAT_WS_BASE_URL',
    defaultValue: 'ws://127.0.0.1:8000/api/chat/ws',
  );

  // Base URL cho hình ảnh (mặc định local backend)
  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Định nghĩa các Base URL theo Role (Dựa trên tài liệu hướng dẫn cập nhật)
  static const String authBaseUrl = '$baseUrl/auth';
  static const String buyerBaseUrl = '$baseUrl/buyer';
  static const String sellerBaseUrl = '$baseUrl/seller';
  static const String adminBaseUrl = '$baseUrl/market-manager';

  // --- API Endpoints (Khớp với Swagger DNGO) ---
  static const String authLoginEndpoint = '/login';
  static const String authRegisterEndpoint = '/register';
  static const String authLogoutEndpoint = '/logout';
  static const String authRefreshEndpoint = '/refresh';
  static const String authMeEndpoint = '/me';

  // Các cấu hình thời gian (Giữ nguyên)
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // App Information
  static const String appName = 'DNGO - Đi Chợ Online';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Pagination & Cache (Giữ nguyên)
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int cacheMaxAge = 3600; 
  static const int maxCacheSize = 50 * 1024 * 1024; 

  // Authentication Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDebugMode = true;
  static const bool enableApiLogging = true;

  // Check environment helpers
  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  /// Lấy Full API URL cho các endpoint chung
  String getApiUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$cleanEndpoint';
  }

  // --- Getters cho Authentication (Sử dụng authBaseUrl) ---
  static String get fullAuthLoginUrl => '$authBaseUrl$authLoginEndpoint';
  static String get fullAuthRegisterUrl => '$authBaseUrl$authRegisterEndpoint';
  static String get fullAuthLogoutUrl => '$authBaseUrl$authLogoutEndpoint';
  static String get fullAuthRefreshUrl => '$authBaseUrl$authRefreshEndpoint';
  static String get fullAuthMeUrl => '$authBaseUrl$authMeEndpoint';
}