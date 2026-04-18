import 'package:flutter/material.dart';
import '../../../../buyer/home/presentation/screen/home_screen.dart';
import '../../../../buyer/product/presentation/screen/product_screen.dart';
import '../../../../buyer/menu/presentation/screen/menu_screen.dart';
import '../../../../buyer/ingredient/presentation/ingredient/screen/ingredient_screen.dart';
import '../../../../user/presentation/screen/user_screen.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/widgets/shared_bottom_navigation.dart';

/// Main Screen với IndexedStack để giữ state của các trang
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Danh sách các trang
  final List<Widget> _pages = const [
    HomeScreen(),
    ProductScreen(),
    MenuScreen(),
    IngredientScreen(),
    UserScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getHeaderTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Món ăn';
      case 2:
        return 'Thực đơn';
      case 3:
        return 'Nguyên liệu';
      case 4:
        return 'Tài khoản';
      default:
        return 'DNGO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _getHeaderTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat',
            onPressed: () {
              Navigator.pushNamed(context, RouteName.chat);
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () {
              Navigator.pushNamed(context, RouteName.cart);
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
