import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/route_name.dart';
import '../cubit/chat_inbox_cubit.dart';

class ChatHubScreen extends StatelessWidget {
  const ChatHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn với người bán'),
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
              onRefresh: () => context.read<ChatInboxCubit>().loadConversations(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Chưa có cuộc trò chuyện nào'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ChatInboxCubit>().loadConversations(),
            child: ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                final title = conversation.getDisplayName(state.role);

                return ListTile(
                  tileColor: conversation.unread > 0
                      ? const Color(0xFFF5F5F5)
                      : Colors.white,
                  leading: CircleAvatar(
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: conversation.unread > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    conversation.tinNhanCuoi ?? 'Nhấn để bắt đầu trò chuyện',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: conversation.unread > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: conversation.unread > 0
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                  trailing: conversation.unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unread}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteName.chatRoom,
                      arguments: {
                        'conversationId': conversation.conversationId,
                        'title': title,
                      },
                    );
                  },
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

  const _ChatErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
