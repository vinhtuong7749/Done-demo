import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/dependency/injection.dart';
import '../../../../core/models/chat_models.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/services/nhom_nguyen_lieu_service.dart';

class ChatRoomState extends Equatable {
  final bool isLoading;
  final bool isSending;
  final bool isSocketConnected;
  final bool isReconnecting;
  final List<ChatMessageModel> messages;
  final String mySenderType;
  final String? mySenderId;
  final String? errorMessage;

  const ChatRoomState({
    this.isLoading = false,
    this.isSending = false,
    this.isSocketConnected = false,
    this.isReconnecting = false,
    this.messages = const [],
    this.mySenderType = 'buyer',
    this.mySenderId,
    this.errorMessage,
  });

  ChatRoomState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isSocketConnected,
    bool? isReconnecting,
    List<ChatMessageModel>? messages,
    String? mySenderType,
    String? mySenderId,
    String? errorMessage,
  }) {
    return ChatRoomState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      messages: messages ?? this.messages,
      mySenderType: mySenderType ?? this.mySenderType,
      mySenderId: mySenderId ?? this.mySenderId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSending,
    isSocketConnected,
    isReconnecting,
    messages,
    mySenderType,
    mySenderId,
    errorMessage,
  ];
}

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final String conversationId;
  final ChatService _chatService;
  final ChatSocketService _socketService;

  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  ChatRoomCubit({
    required this.conversationId,
    ChatService? chatService,
    ChatSocketService? socketService,
  }) : _chatService = chatService ?? getIt<ChatService>(),
       _socketService = socketService ?? getIt<ChatSocketService>(),
       super(const ChatRoomState());

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final role = await _chatService.getCurrentRole();
      final senderType = role == 'nguoi_mua' ? 'buyer' : 'seller';
      final senderId = await _chatService.getCurrentUserId();

      final page = await _chatService.getMessages(
        conversationId,
        page: 1,
        limit: 50,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          isLoading: false,
          mySenderType: senderType,
          mySenderId: senderId,
          messages: page.messages,
        ),
      );

      await _connectSocket();
      await _socketService.sendReadEvent();
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

  Future<void> sendMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty || state.isSending) {
      return;
    }

    emit(state.copyWith(isSending: true, errorMessage: null));

    try {
      final message = await _chatService.sendMessage(
        conversationId,
        messageText: text,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          isSending: false,
          messages: _appendMessage(state.messages, message),
        ),
      );

      await _socketService.sendReadEvent();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> sendImage(File imageFile) async {
    if (state.isSending) {
      return;
    }

    emit(state.copyWith(isSending: true, errorMessage: null));

    try {
      final uploadResponse = await NhomNguyenLieuService.uploadImages(
        files: [imageFile],
        folder: 'chat',
      );

      if (!uploadResponse.success || uploadResponse.urls.isEmpty) {
        throw Exception(uploadResponse.message ?? 'Không thể tải ảnh lên');
      }

      final message = await _chatService.sendMessage(
        conversationId,
        imageUrl: uploadResponse.urls.first,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          isSending: false,
          messages: _appendMessage(state.messages, message),
        ),
      );

      await _socketService.sendReadEvent();
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> refreshMessages() async {
    try {
      final page = await _chatService.getMessages(
        conversationId,
        page: 1,
        limit: 50,
      );
      if (isClosed) return;
      emit(state.copyWith(messages: page.messages));
      await _socketService.sendReadEvent();
    } catch (_) {
      // Keep current messages when refresh fails.
    }
  }

  Future<void> _connectSocket() async {
    await _socketSubscription?.cancel();

    _socketSubscription = _socketService.events.listen(_handleSocketEvent);

    try {
      await _socketService.connect(conversationId);
      if (isClosed) return;
      emit(state.copyWith(isSocketConnected: true, isReconnecting: false));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSocketConnected: false,
          isReconnecting: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    if (isClosed) return;

    final type = (event['type'] ?? '').toString();

    if (type == 'connection.ready') {
      emit(state.copyWith(isSocketConnected: true, isReconnecting: false));
      return;
    }

    if (type == 'socket.disconnected') {
      emit(state.copyWith(isSocketConnected: false, isReconnecting: true));
      return;
    }

    if (type == 'socket.reconnecting') {
      emit(state.copyWith(isSocketConnected: false, isReconnecting: true));
      return;
    }

    if (type == 'message.created') {
      final data = event['data'];
      if (data is Map<String, dynamic>) {
        final incoming = ChatMessageModel.fromJson(data);
        emit(
          state.copyWith(messages: _appendMessage(state.messages, incoming)),
        );
      }
      return;
    }

    if (type == 'typing' || type == 'pong') {
      return;
    }

    if (type == 'message.read') {
      refreshMessages();
      return;
    }

    if (type == 'error' || type == 'socket.error') {
      final msg = (event['message'] ?? 'Lỗi realtime chat').toString();
      emit(state.copyWith(errorMessage: msg));
    }
  }

  List<ChatMessageModel> _appendMessage(
    List<ChatMessageModel> current,
    ChatMessageModel incoming,
  ) {
    final exists = current.any((item) => item.messageId == incoming.messageId);
    if (exists) {
      return current;
    }

    final updated = [...current, incoming]
      ..sort((a, b) {
        final at = a.sentAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.sentAt?.millisecondsSinceEpoch ?? 0;
        return at.compareTo(bt);
      });

    return updated;
  }

  @override
  Future<void> close() async {
    await _socketSubscription?.cancel();
    await _socketService.disconnect();
    return super.close();
  }
}
