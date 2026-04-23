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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
