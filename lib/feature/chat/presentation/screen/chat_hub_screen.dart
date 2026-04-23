import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/route_name.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../cubit/chat_inbox_cubit.dart';

class ChatHubScreen extends StatelessWidget {
  const ChatHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6), // Stitch Mint background
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF1B5E20), // Forest Green
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
        centerTitle: true,
      ),
      body: const _BuyerSellerTab(),
    );
  }
}

class _BuyerSellerTab extends StatelessWidget {
  const _BuyerSellerTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatInboxCubit()..loadConversations(),
      child: BlocBuilder<ChatInboxCubit, ChatInboxState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.conversations.isEmpty) {
            return _ChatErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<ChatInboxCubit>().loadConversations(),
            );
          }

          if (state.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<ChatInboxCubit>().loadConversations(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Chưa có cuộc trò chuyện nào')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ChatInboxCubit>().loadConversations(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final title = conversation.getDisplayName(state.role);
                final mySenderType = state.role == 'nguoi_mua'
                    ? 'buyer'
                    : 'seller';
                final isLastMessageMine =
                    (state.currentUserId != null &&
                        state.currentUserId!.isNotEmpty)
                    ? conversation.lastSenderId == state.currentUserId
                    : conversation.lastSenderType == mySenderType;
                final previewText =
                    conversation.tinNhanCuoi == null ||
                        conversation.tinNhanCuoi!.isEmpty
                    ? 'Nhấn để bắt đầu trò chuyện'
                    : isLastMessageMine
                    ? 'Bạn: ${conversation.tinNhanCuoi}'
                    : conversation.tinNhanCuoi!;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2F5E5), // Light green background
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF1B5E20), // Forest Green
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: const Color(0xFF1B5E20),
                        fontWeight: conversation.unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: conversation.unread > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: conversation.unread > 0
                              ? const Color(0xFF1C1C1E) // Dark black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    trailing: conversation.unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935), // Alert Red
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unread}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                    onTap: () async {
                      final cubit = context.read<ChatInboxCubit>();
                      cubit.markConversationAsRead(conversation.conversationId);

                      await Navigator.pushNamed(
                        context,
                        RouteName.chatRoom,
                        arguments: {
                          'conversationId': conversation.conversationId,
                          'title': title,
                        },
                      );

                      if (!context.mounted) return;
                      await cubit.loadConversations();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(message: message, onRetry: onRetry);
  }
}
