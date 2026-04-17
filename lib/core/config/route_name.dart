/// Định nghĩa tên các route trong ứng dụng
/// Sử dụng để navigate giữa các màn hình
class RouteName {
  RouteName._();

  // Main Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/home';
  
  // Seller Routes
  static const String sellerMain = '/seller/main';
  static const String sellerHome = '/seller/home';
  static const String sellerOrder = '/seller/order';
  static const String sellerRevenue = '/seller/revenue';
  static const String sellerAddIngredient = '/seller/add-ingredient';
  static const String sellerEditIngredient = '/seller/edit-ingredient';
  static const String sellerUpdateIngredient = '/seller/update-ingredient';
  static const String sellerUser = '/seller/user';

  // Admin Routes
  static const String adminHome = '/admin/home';
  static const String adminMap = '/admin/map';
  static const String adminUpdateStall = '/admin/map/update-stall';
  static const String adminSellerManagement = '/admin/seller-management';
  static const String adminUser = '/admin/user';
  static const String adminMarketInfo = '/admin/market-info';

  // Authentication Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';

  // Product Routes
  static const String productList = '/products';
  static const String productDetail = '/product-detail';
  static const String productSearch = '/product-search';
  static const String productFilter = '/product-filter';
  static const String menuDetail = '/menu-detail';
  static const String search = '/search';
  static const String categoryProducts = '/category-products';
  static const String categoryIngredients = '/category-ingredients';
  static const String allShops = '/all-shops';
  static const String ingredient = '/ingredient';
  static const String ingredientDetail = '/ingredient-detail';
  static const String shop = '/shop';



  // Category Routes
  static const String categoryList = '/categories';
  static const String categoryDetail = '/category-detail';

  // Cart Routes
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String checkoutSuccess = '/checkout-success';
  static const String payment = '/payment';

  // Order Routes
  static const String orderList = '/orders';
  static const String orderDetail = '/order-detail';
  static const String orderTracking = '/order-tracking';

  // User Routes
  static const String user = '/user';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String address = '/address';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';

  // Settings Routes
  static const String settings = '/settings';
  static const String language = '/language';
  static const String theme = '/theme';
  static const String notification = '/notification';
  static const String about = '/about';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';

  // Other Routes
  static const String favorites = '/favorites';
  static const String reviews = '/reviews';
  static const String writeReview = '/write-review';
  static const String support = '/support';
  static const String chat = '/chat';
  static const String chatRoom = '/chat-room';
}
