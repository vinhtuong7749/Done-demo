import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../../core/services/llm_chatbot_service.dart';
import '../../../../../core/models/llm_chat_models.dart';
import '../../../../../core/services/auth/auth_service.dart';
import '../../../../../core/dependency/injection.dart';

/// Cubit quản lý state cho Home Screen
class HomeCubit extends Cubit<HomeState> {
  final LlmChatbotService _llmService = getIt<LlmChatbotService>();
  final AuthService _authService = getIt<AuthService>();

  HomeCubit() : super(const HomeState());

  /// Khởi tạo màn hình home với tin nhắn chào mừng
  Future<void> initializeHome() async {
    // Lấy tên user từ local storage
    String userName = 'bạn';
    try {
      final userData = await _authService.getUserData();
      if (userData != null && userData.tenDangNhap.isNotEmpty) {
        userName = userData.tenDangNhap;
      }
    } catch (e) {
      // Nếu lỗi, dùng tên mặc định
    }

    final welcomeMessage = ChatMessage(
      message: 'Chào buổi sáng $userName, bạn muốn nấu món gì hôm nay?',
      isBot: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      userName: userName,
      chatMessages: [welcomeMessage],
    ));
  }

  /// Gửi tin nhắn từ người dùng
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      message: message,
      isBot: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.chatMessages, userMessage];
    emit(state.copyWith(chatMessages: updatedMessages, isTyping: true));

    // Gọi API chat AI
    await _sendToAI(message);
  }

  /// Gửi tin nhắn đến LLM API và nhận phản hồi
  Future<void> _sendToAI(String message) async {
    try {
      // Build history from current state
      final historyItems = state.history;

      final response = await _llmService.sendMessage(
        message: message,
        sessionId: state.conversationId,
        history: historyItems,
      );

      if (isClosed) return;

      // Map LLM dishes to MonAnSuggestion
      List<MonAnSuggestion>? monAnSuggestions;
      if (response.dishes.isNotEmpty) {
        monAnSuggestions = response.dishes.map((dish) {
          return MonAnSuggestion(
            maMonAn: (dish.raw['dish_id'] ?? dish.raw['ma_mon_an'] ?? '').toString(),
            tenMonAn: dish.title,
            hinhAnh: (dish.raw['image'] ?? dish.raw['hinh_anh'] ?? '').toString(),
          );
        }).toList();
      }

      // Create bot message
      final botMessage = ChatMessage(
        message: response.reply.isNotEmpty
            ? response.reply
            : 'Mình chưa có dữ liệu phù hợp, bạn thử nói rõ hơn nhé.',
        isBot: true,
        timestamp: DateTime.now(),
        responseType: response.dishes.isNotEmpty ? 'suggestions' : 'text',
        monAnSuggestions: monAnSuggestions,
        hint: response.shops.isNotEmpty
            ? 'Tìm thấy ${response.shops.length} gian hàng'
            : null,
      );

      // Update history
      final updatedHistory = [
        ...historyItems,
        LlmChatHistoryItem(role: 'user', content: message),
        LlmChatHistoryItem(role: 'assistant', content: response.reply),
      ];

      final updatedMessages = [...state.chatMessages, botMessage];
      emit(state.copyWith(
        chatMessages: updatedMessages,
        isTyping: false,
        conversationId: response.sessionId.isNotEmpty ? response.sessionId : state.conversationId,
        history: updatedHistory,
      ));
    } catch (e) {
      debugPrint('❌ Error sending message to LLM: $e');

      if (isClosed) return;

      final errorMessage = ChatMessage(
        message: 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.',
        isBot: true,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...state.chatMessages, errorMessage];
      emit(state.copyWith(
        chatMessages: updatedMessages,
        isTyping: false,
      ));
    }
  }

  /// Chọn option từ chat
  void selectOption(ChatOption option) {
    sendMessage(option.label);
  }

  /// Cập nhật search query
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Thực hiện tìm kiếm
  void performSearch() {
    if (state.searchQuery.trim().isNotEmpty) {
      // Navigate to search results
      sendMessage(state.searchQuery);
      emit(state.copyWith(searchQuery: ''));
    }
  }

  /// Thay đổi bottom navigation index
  void changeBottomNavIndex(int index) {
    emit(state.copyWith(selectedBottomNavIndex: index));
  }

  /// Thêm vào giỏ hàng
  void addToCart() {
    emit(state.copyWith(cartItemCount: state.cartItemCount + 1));
  }
}
