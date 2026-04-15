import 'package:equatable/equatable.dart';

import '../../../../../core/models/llm_chat_models.dart';

/// State cho Home Screen
class HomeState extends Equatable {
  final String userName;
  final String searchQuery;
  final List<ChatMessage> chatMessages;
  final bool isTyping;
  final int selectedBottomNavIndex;
  final int cartItemCount;
  final String? errorMessage;
  final String? conversationId;
  final List<LlmChatHistoryItem> history;

  const HomeState({
    this.userName = 'Quỳnh Như',
    this.searchQuery = '',
    this.chatMessages = const [],
    this.isTyping = false,
    this.selectedBottomNavIndex = 0,
    this.cartItemCount = 0,
    this.errorMessage,
    this.conversationId,
    this.history = const [],
  });

  HomeState copyWith({
    String? userName,
    String? searchQuery,
    List<ChatMessage>? chatMessages,
    bool? isTyping,
    int? selectedBottomNavIndex,
    int? cartItemCount,
    String? errorMessage,
    String? conversationId,
    List<LlmChatHistoryItem>? history,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      searchQuery: searchQuery ?? this.searchQuery,
      chatMessages: chatMessages ?? this.chatMessages,
      isTyping: isTyping ?? this.isTyping,
      selectedBottomNavIndex: selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      errorMessage: errorMessage ?? this.errorMessage,
      conversationId: conversationId ?? this.conversationId,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        searchQuery,
        chatMessages,
        isTyping,
        selectedBottomNavIndex,
        cartItemCount,
        errorMessage,
        conversationId,
        history,
      ];
}

/// Model cho tin nhắn chat
class ChatMessage extends Equatable {
  final String message;
  final bool isBot;
  final DateTime timestamp;
  final String? responseType; // 'text', 'menu_selection', 'suggestions', 'menu_detail'
  final List<ChatOption>? options;
  final List<MonAnSuggestion>? monAnSuggestions;
  final List<NguyenLieuSuggestion>? nguyenLieuSuggestions;
  final List<MenuSelection>? menus; // Menu selection
  final SelectedMenuDetail? selectedMenu; // Menu detail after selection
  final String? hint;

  const ChatMessage({
    required this.message,
    required this.isBot,
    required this.timestamp,
    this.responseType,
    this.options,
    this.monAnSuggestions,
    this.nguyenLieuSuggestions,
    this.menus,
    this.selectedMenu,
    this.hint,
  });

  @override
  List<Object?> get props => [
        message,
        isBot,
        timestamp,
        responseType,
        options,
        monAnSuggestions,
        nguyenLieuSuggestions,
        menus,
        selectedMenu,
        hint,
      ];
}

/// Model cho món ăn suggestion từ AI
class MonAnSuggestion extends Equatable {
  final String maMonAn;
  final String tenMonAn;
  final String hinhAnh;

  const MonAnSuggestion({
    required this.maMonAn,
    required this.tenMonAn,
    required this.hinhAnh,
  });

  @override
  List<Object?> get props => [maMonAn, tenMonAn, hinhAnh];
}

/// Model cho nguyên liệu suggestion từ AI
class NguyenLieuSuggestion extends Equatable {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String? dinhLuong;
  final String? hinhAnh;
  final GianHangSuggest? gianHangSuggest;
  final bool canAddToCart;

  const NguyenLieuSuggestion({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    this.dinhLuong,
    this.hinhAnh,
    this.gianHangSuggest,
    this.canAddToCart = false,
  });

  @override
  List<Object?> get props => [maNguyenLieu, tenNguyenLieu, donVi, dinhLuong, hinhAnh, gianHangSuggest, canAddToCart];
}

/// Model cho gian hàng suggest
class GianHangSuggest extends Equatable {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String gia;
  final String donViBan;
  final double soLuong;

  const GianHangSuggest({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.gia,
    required this.donViBan,
    required this.soLuong,
  });

  @override
  List<Object?> get props => [maGianHang, tenGianHang, viTri, gia, donViBan, soLuong];
}

/// Model cho các lựa chọn trong chat
class ChatOption extends Equatable {
  final String label;
  final String value;
  final bool isSelected;

  const ChatOption({
    required this.label,
    required this.value,
    this.isSelected = false,
  });

  ChatOption copyWith({
    String? label,
    String? value,
    bool? isSelected,
  }) {
    return ChatOption(
      label: label ?? this.label,
      value: value ?? this.value,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [label, value, isSelected];
}


/// Model cho menu selection
class MenuSelection extends Equatable {
  final String menuId;
  final String tenMenu;
  final String moTa;
  final String phuHopVoi;
  final String icon;
  final List<MenuDish> monAn;

  const MenuSelection({
    required this.menuId,
    required this.tenMenu,
    required this.moTa,
    required this.phuHopVoi,
    required this.icon,
    required this.monAn,
  });

  @override
  List<Object?> get props => [menuId, tenMenu, moTa, phuHopVoi, icon, monAn];
}

/// Model cho món ăn trong menu
class MenuDish extends Equatable {
  final String maMonAn;
  final String tenMonAn;
  final String vaiTro;

  const MenuDish({
    required this.maMonAn,
    required this.tenMonAn,
    required this.vaiTro,
  });

  @override
  List<Object?> get props => [maMonAn, tenMonAn, vaiTro];
}

/// Model cho menu detail (sau khi chọn menu)
class SelectedMenuDetail extends Equatable {
  final String menuId;
  final String tenMenu;
  final String moTa;
  final String phuHopVoi;
  final String icon;
  final List<MonAnDetail> monAn;

  const SelectedMenuDetail({
    required this.menuId,
    required this.tenMenu,
    required this.moTa,
    required this.phuHopVoi,
    required this.icon,
    required this.monAn,
  });

  @override
  List<Object?> get props => [menuId, tenMenu, moTa, phuHopVoi, icon, monAn];
}

/// Model cho món ăn chi tiết
class MonAnDetail extends Equatable {
  final String maMonAn;
  final String tenMonAn;
  final String hinhAnh;
  final int khoangThoiGian;
  final String doKho;
  final int khauPhanTieuChuan;
  final int calories;
  final List<NguyenLieuDetail> nguyenLieu;

  const MonAnDetail({
    required this.maMonAn,
    required this.tenMonAn,
    required this.hinhAnh,
    required this.khoangThoiGian,
    required this.doKho,
    required this.khauPhanTieuChuan,
    required this.calories,
    required this.nguyenLieu,
  });

  @override
  List<Object?> get props => [maMonAn, tenMonAn, hinhAnh, khoangThoiGian, doKho, khauPhanTieuChuan, calories, nguyenLieu];
}

/// Model cho nguyên liệu chi tiết trong món ăn
class NguyenLieuDetail extends Equatable {
  final String maNguyenLieu;
  final String ten;
  final String? dinhLuong;
  final String? donVi;
  final List<GianHangDetail> gianHang;

  const NguyenLieuDetail({
    required this.maNguyenLieu,
    required this.ten,
    this.dinhLuong,
    this.donVi,
    required this.gianHang,
  });

  @override
  List<Object?> get props => [maNguyenLieu, ten, dinhLuong, donVi, gianHang];
}

/// Model cho gian hàng chi tiết
class GianHangDetail extends Equatable {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String maCho;
  final String gia;
  final String donViBan;
  final double soLuong;

  const GianHangDetail({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.maCho,
    required this.gia,
    required this.donViBan,
    required this.soLuong,
  });

  @override
  List<Object?> get props => [maGianHang, tenGianHang, viTri, maCho, gia, donViBan, soLuong];
}
