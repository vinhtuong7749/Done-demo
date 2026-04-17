import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../feature/buyer/home/presentation/cubit/home_state.dart';
import 'chat_option_widget.dart';
import 'mon_an_suggestion_card.dart';
import 'nguyen_lieu_suggestion_card.dart';
import 'gian_hang_suggestion_card.dart';
import 'menu_selection_card.dart';
import 'menu_detail_card.dart';
import '../../router/app_router.dart';
import '../../config/route_name.dart';
import '../../config/app_config.dart';
import '../../utils/app_logger.dart';
import '../../models/chat_ai_model.dart' as chat_model;
import '../../services/cart_api_service.dart';

/// Widget hiển thị một tin nhắn trong chat
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(ChatOption) onOptionTap;
  final Function(String)? onMenuSelected;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.onOptionTap,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset('assets/img/logo.png', fit: BoxFit.cover),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: message.isBot
                        ? Colors.white
                        : const Color(0x4D008EDB),
                    borderRadius: message.isBot
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                    border: message.isBot
                        ? Border.all(color: const Color(0xFFE0E0E0), width: 1)
                        : null,
                  ),
                  child: message.isBot
                      ? MarkdownBody(
                          data: message.message,
                          selectable: true,
                          softLineBreak: true,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w300,
                                  height: 1.33,
                                  color: Colors.black,
                                ),
                                h1: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                h2: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                h3: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                strong: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                listBullet: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 17,
                                  color: Colors.black,
                                ),
                                blockquote: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  height: 1.4,
                                  color: Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                                code: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  color: Color(0xFF1A1A1A),
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: const Color(0xFFF4F6F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                        )
                      : Text(
                          message.message,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 17,
                            fontWeight: FontWeight.w300,
                            height: 1.33,
                            color: Colors.black,
                          ),
                        ),
                ),
                if (message.options != null && message.options!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.options!
                          .map(
                            (option) => ChatOptionWidget(
                              option: option,
                              onTap: () => onOptionTap(option),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (message.monAnSuggestions != null &&
                    message.monAnSuggestions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.monAnSuggestions!.length,
                        itemBuilder: (context, index) {
                          final monAn = message.monAnSuggestions![index];
                          return MonAnSuggestionCard(
                            monAn: monAn,
                            onTap: () => AppRouter.navigateTo(
                              context,
                              RouteName.productDetail,
                              arguments: monAn.maMonAn,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (message.nguyenLieuSuggestions != null &&
                    message.nguyenLieuSuggestions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.nguyenLieuSuggestions!.length,
                        itemBuilder: (context, index) {
                          final nguyenLieu =
                              message.nguyenLieuSuggestions![index];
                          final chatModelNguyenLieu =
                              chat_model.NguyenLieuSuggestion(
                                maNguyenLieu: nguyenLieu.maNguyenLieu,
                                tenNguyenLieu: nguyenLieu.tenNguyenLieu,
                                donVi: nguyenLieu.donVi,
                                dinhLuong: nguyenLieu.dinhLuong,
                                hinhAnh: nguyenLieu.hinhAnh,
                                gianHangSuggest:
                                    nguyenLieu.gianHangSuggest != null
                                    ? chat_model.GianHangSuggest(
                                        maGianHang: nguyenLieu
                                            .gianHangSuggest!
                                            .maGianHang,
                                        tenGianHang: nguyenLieu
                                            .gianHangSuggest!
                                            .tenGianHang,
                                        viTri:
                                            nguyenLieu.gianHangSuggest!.viTri,
                                        gia: nguyenLieu.gianHangSuggest!.gia,
                                        donViBan: nguyenLieu
                                            .gianHangSuggest!
                                            .donViBan,
                                        soLuong:
                                            nguyenLieu.gianHangSuggest!.soLuong,
                                      )
                                    : null,
                                actions: chat_model.NguyenLieuActions(
                                  canViewDetail: true,
                                  canAddToCart: nguyenLieu.canAddToCart,
                                  detailEndpoint:
                                      '/api/buyer/nguyen-lieu/${nguyenLieu.maNguyenLieu}',
                                  addToCartEndpoint: nguyenLieu.canAddToCart
                                      ? '/api/cart'
                                      : null,
                                ),
                              );
                          return NguyenLieuSuggestionCard(
                            nguyenLieu: chatModelNguyenLieu,
                            onTap: () => AppRouter.navigateTo(
                              context,
                              RouteName.ingredientDetail,
                              arguments: {
                                'maNguyenLieu': nguyenLieu.maNguyenLieu,
                                'name': nguyenLieu.tenNguyenLieu,
                                'image': '',
                                'price': nguyenLieu.gianHangSuggest?.gia ?? '',
                                'unit': nguyenLieu.gianHangSuggest?.donViBan,
                                'shopName':
                                    nguyenLieu.gianHangSuggest?.tenGianHang,
                              },
                            ),
                            onAddToCart:
                                nguyenLieu.canAddToCart &&
                                    nguyenLieu.gianHangSuggest != null
                                ? () async {
                                    try {
                                      await CartApiService().addToCart(
                                        maNguyenLieu: nguyenLieu.maNguyenLieu,
                                        maGianHang: nguyenLieu
                                            .gianHangSuggest!
                                            .maGianHang,
                                        soLuong: 1.0,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Đã thêm vào giỏ hàng',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi: ${e.toString()}',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                // Gian hàng suggestions
                if (message.gianHangSuggestions != null &&
                    message.gianHangSuggestions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 400,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: message.gianHangSuggestions!.length,
                        itemBuilder: (context, index) {
                          final gianHang = message.gianHangSuggestions![index];
                          return GianHangSuggestionCard(
                            gianHang: gianHang,
                            onTap: () {
                              // Extract suggested products with full data
                              final suggestedProducts = gianHang
                                  .toShopProducts();

                              if (AppConfig.enableApiLogging) {
                                AppLogger.info(
                                  '🏪 [NAVIGATION] Navigating to shop: ${gianHang.maGianHang}',
                                );
                                AppLogger.info(
                                  '📌 [NAVIGATION] Suggested products: ${suggestedProducts.length} items',
                                );
                              }

                              // Navigate to shop detail page with suggested products
                              Navigator.pushNamed(
                                context,
                                RouteName.shop,
                                arguments: {
                                  'shopId': gianHang.maGianHang,
                                  'suggestedProducts': suggestedProducts,
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                // Menu selection cards
                if (message.menus != null && message.menus!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 320,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: message.menus!.length,
                            itemBuilder: (context, index) {
                              final menu = message.menus![index];
                              return MenuSelectionCard(
                                menu: menu,
                                onTap: () {
                                  if (onMenuSelected != null) {
                                    onMenuSelected!('Menu ${menu.menuId}');
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        if (message.hint != null && message.hint!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              message.hint!,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Menu detail cards (after selection) - scroll ngang
                if (message.selectedMenu != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 580,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: message.selectedMenu!.monAn.length,
                            itemBuilder: (context, index) {
                              final monAn = message.selectedMenu!.monAn[index];
                              return MenuDetailCard(monAn: monAn);
                            },
                          ),
                        ),
                        if (message.hint != null && message.hint!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              message.hint!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
