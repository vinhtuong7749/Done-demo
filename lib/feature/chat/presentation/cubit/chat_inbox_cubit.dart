import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/dependency/injection.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/services/chat_service.dart';

class ChatInboxState extends Equatable {
  final bool isLoading;
  final List<ChatConversation> conversations;
  final String role;
  final String? currentUserId;
  final String? errorMessage;

  const ChatInboxState({
    this.isLoading = false,
    this.conversations = const [],
    this.role = 'nguoi_mua',
    this.currentUserId,
    this.errorMessage,
  });

  ChatInboxState copyWith({
    bool? isLoading,
    List<ChatConversation>? conversations,
    String? role,
    String? currentUserId,
    String? errorMessage,
  }) {
    return ChatInboxState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      role: role ?? this.role,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    conversations,
    role,
    currentUserId,
    errorMessage,
  ];
}

class ChatInboxCubit extends Cubit<ChatInboxState> {
  final ChatService _chatService;

  ChatInboxCubit({ChatService? chatService})
    : _chatService = chatService ?? getIt<ChatService>(),
      super(const ChatInboxState());

  Future<void> loadConversations() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final role = await _chatService.getCurrentRole();
      final currentUserId = await _chatService.getCurrentUserId();
      final conversations = await _chatService.getConversations();

      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          role: role,
          currentUserId: currentUserId,
          conversations: conversations,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<ChatCreateConversationResponse> createConversationForStall(
    String stallId,
  ) {
    return _chatService.createConversation(stallId);
  }

  void markConversationAsRead(String conversationId) {
    final updatedConversations = state.conversations.map((conversation) {
      if (conversation.conversationId != conversationId ||
          conversation.unread == 0) {
        return conversation;
      }

      return ChatConversation(
        conversationId: conversation.conversationId,
        stallId: conversation.stallId,
        buyerId: conversation.buyerId,
        tenGianHang: conversation.tenGianHang,
        tenNguoiMua: conversation.tenNguoiMua,
        tinNhanCuoi: conversation.tinNhanCuoi,
        thoiGianCuoi: conversation.thoiGianCuoi,
        lastSenderId: conversation.lastSenderId,
        lastSenderType: conversation.lastSenderType,
        unread: 0,
      );
    }).toList();

    emit(state.copyWith(conversations: updatedConversations));
  }
}
