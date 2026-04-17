import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import '../../feature/buyer/home/presentation/cubit/home_state.dart';
import '../../feature/buyer/ingredient/presentation/ingredient_detail/screen/ingredient_detail_page.dart';
import '../../feature/buyer/ingredient/presentation/category_ingredient/screen/category_ingredient_screen.dart';
import '../../feature/buyer/shops/presentation/screen/all_shops_screen.dart';
import '../../feature/buyer/shop/presentation/shop_page.dart';
import '../../feature/buyer/shop/presentation/shop_cubit.dart';
import '../../feature/seller/ingredient/presentation/cubit/ingredient_state.dart';
import '../../feature/seller/ingredient/add/presentation/screen/add_ingredient_screen.dart';
import '../../feature/seller/ingredient/update/presentation/screen/update_ingredient_screen.dart';
import '../../feature/seller/user/presentation/screen/seller_user_screen.dart';
import '../../feature/seller/main/presentation/screen/seller_main_screen.dart';
import '../../feature/seller/order/presentation/screen/order_screen.dart';
import '../../feature/seller/revenue/presentation/screen/revenue_screen.dart';
import '../../feature/admin/home/presentation/screen/admin_home_screen.dart';
import '../../feature/admin/map/presentation/screen/admin_map_screen.dart';
import '../../feature/admin/map/update/presentation/screen/update_stall_screen.dart';
import '../models/market_map_model.dart';
import '../../feature/admin/seller/presentation/screen/seller_management_screen.dart';
import '../../feature/admin/user/presentation/screen/admin_user_screen.dart';
import '../../feature/admin/market/presentation/screen/market_info_screen.dart';
import '../config/route_name.dart';
import '../../feature/splash/presentation/screen/splash_page.dart';
import '../../feature/login/presentation/screen/login_page.dart';
import '../../feature/signup/presentation/screen/signup_page.dart';
import '../../feature/buyer/main/presentation/screen/main_screen.dart';
import '../../feature/buyer/productdetail/presentation/screen/productdetail_screen.dart';
import '../../feature/buyer/menudetail/presentation/screen/menudetail_screen.dart';
import '../../feature/buyer/review/presentation/screen/review_page.dart';
import '../../feature/buyer/cart/presentation/screen/cart_page.dart';
import '../../feature/buyer/payment/presentation/screen/payment_page.dart';
import '../../feature/buyer/order/presentation/order_detail/screen/order_detail_page.dart';
import '../../feature/buyer/order/presentation/order/screen/order_page.dart';
import '../../feature/buyer/search/presentation/screen/search_screen.dart';
import '../../feature/buyer/product/presentation/screen/category_product_screen.dart';
import '../../feature/user/presentation/edit_profile/screen/edit_profile_page.dart';
import '../../feature/chat/presentation/screen/chat_hub_screen.dart';
import '../../feature/chat/presentation/screen/chat_room_screen.dart';

/// Quản lý navigation và routing của ứng dụng
/// Sử dụng onGenerateRoute để tạo route động
class AppRouter {
  AppRouter._();

  /// Global navigator key to access navigator without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Generate route based on route settings
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
        return _buildRoute(settings, const SplashPage());

      case RouteName.main:
        final args = settings.arguments as int?;
        return _buildRoute(settings, MainScreen(initialIndex: args ?? 0));

      case RouteName.home:
        return _buildRoute(settings, const MainScreen(initialIndex: 0));

      case RouteName.login:
        return _buildRoute(settings, const LoginPage());

      case RouteName.ingredient:
        return _buildRoute(settings, const MainScreen(initialIndex: 3));

      case RouteName.ingredientDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          IngredientDetailPage(
            maNguyenLieu: args?['maNguyenLieu'],
            ingredientName: args?['name'] ?? '',
            ingredientImage: args?['image'] ?? '',
            price: args?['price'] ?? '',
            unit: args?['unit'],
            shopName: args?['shopName'],
          ),
        );

      case RouteName.register:
        return _buildRoute(settings, const SignUpPage());

      case RouteName.productList:
        return _buildRoute(settings, const MainScreen(initialIndex: 1));

      case RouteName.productDetail:
        return _buildRoute(settings, const ProductDetailScreen());

      case RouteName.menuDetail:
        return _buildRoute(settings, const MenuDetailScreen());

      case RouteName.user:
        return _buildRoute(settings, const MainScreen(initialIndex: 4));

      case RouteName.reviews:
        return _buildRoute(settings, const ReviewPage());

      case RouteName.cart:
        return _buildRoute(settings, const CartPage());

      case RouteName.payment:
      case RouteName.checkout:
        return _buildRoute(settings, const PaymentPage());

      case RouteName.orderDetail:
        return _buildRoute(
          settings,
          OrderDetailPage(orderId: settings.arguments as String?),
        );

      case RouteName.orderList:
        return _buildRoute(settings, const OrderPage());

      case RouteName.search:
        return _buildRoute(settings, const SearchScreen());

      case RouteName.chat:
        return _buildRoute(settings, const ChatHubScreen());

      case RouteName.chatRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          ChatRoomScreen(
            conversationId: (args?['conversationId'] ?? '').toString(),
            title: (args?['title'] ?? 'Trò chuyện').toString(),
          ),
        );

      case RouteName.categoryProducts:
        final args = settings.arguments as Map<String, String>?;
        return _buildRoute(
          settings,
          CategoryProductScreen(
            categoryId: args?['categoryId'] ?? '',
            categoryName: args?['categoryName'] ?? 'Danh mục',
          ),
        );

      case RouteName.categoryIngredients:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          settings,
          CategoryIngredientScreen(
            categoryId: args?['categoryId']?.toString() ?? '',
            categoryName: args?['categoryName']?.toString() ?? 'Danh mục',
          ),
        );

      case RouteName.allShops:
        return _buildRoute(settings, const AllShopsScreen());

      case RouteName.profile:
        return _buildRoute(settings, const _PlaceholderScreen(title: 'Profile Screen'));

      case RouteName.editProfile:
        return _buildRoute(settings, const EditProfilePage());

      case RouteName.shop:
        final args = settings.arguments;
        String shopId = '';
        List<ShopProductPreview>? suggestedProducts;

        if (args is String) {
          // Backward compatibility: chỉ có shopId
          shopId = args;
          if (AppConfig.enableApiLogging) {
            AppLogger.info('🏪 [ROUTER] Shop navigation (String): $shopId');
          }
        } else if (args is Map) {
          // Mới: có cả shopId và suggestedProducts
          shopId = args['shopId'] as String? ?? '';
          suggestedProducts = args['suggestedProducts'] as List<ShopProductPreview>?;
          if (AppConfig.enableApiLogging) {
            AppLogger.info('🏪 [ROUTER] Shop navigation (Map):');
            AppLogger.info('   shopId: $shopId');
            AppLogger.info('   suggestedProducts: ${suggestedProducts?.length ?? 0} items');
          }
        }

        return _buildRoute(
          settings,
          BlocProvider(
            create: (_) => ShopCubit(),
            child: ShopPage(
              shopId: shopId,
              suggestedProducts: suggestedProducts,
            ),
          ),
        );

      // Seller Routes
      case RouteName.sellerMain:
      case RouteName.sellerHome:
        final initialIndex = settings.arguments as int? ?? 0;
        return _buildRoute(settings, SellerMainScreen(initialIndex: initialIndex));

      case RouteName.sellerAddIngredient:
        return _buildRoute(settings, const AddIngredientScreen());

      case RouteName.sellerUpdateIngredient:
        final ingredient = settings.arguments as SellerIngredient;
        return _buildRoute(settings, UpdateIngredientScreen(ingredient: ingredient));

      case RouteName.sellerUser:
        return _buildRoute(settings, const SellerUserScreen());

      case RouteName.sellerOrder:
        return _buildRoute(settings, const SellerOrderScreen());

      case RouteName.sellerRevenue:
        return _buildRoute(settings, const SellerRevenueScreen());

      // Admin Routes
      case RouteName.adminHome:
        return _buildRoute(settings, const AdminHomeScreen());

      case RouteName.adminMap:
        return _buildRoute(settings, const AdminMapScreen());

      case RouteName.adminUpdateStall:
        final store = settings.arguments as MapStoreInfo?;
        return _buildRoute(settings, UpdateStallScreen(store: store));

      case RouteName.adminSellerManagement:
        return _buildRoute(settings, const SellerManagementScreen());

      case RouteName.adminUser:
        return _buildRoute(settings, const AdminUserScreen());

      case RouteName.adminMarketInfo:
        return _buildRoute(settings, const MarketInfoScreen());

      default:
        return _buildRoute(settings, const _NotFoundScreen());
    }
  }

  static MaterialPageRoute _buildRoute(RouteSettings settings, Widget page) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> navigateAndRemoveUntil<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(context, routeName, (route) => false, arguments: arguments);
  }

  static Future<T?> navigateAndReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, void>(context, routeName, arguments: arguments);
  }

  static void goBack(BuildContext context, {Object? result}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => AppRouter.goBack(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Không tìm thấy trang', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => AppRouter.goBack(context),
              icon: const Icon(Icons.home),
              label: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
