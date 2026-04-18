import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../cubit/chat_room_cubit.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChatRoomCubit(conversationId: widget.conversationId)..initialize(),
      child: BlocConsumer<ChatRoomCubit, ChatRoomState>(
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });

          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title.isNotEmpty ? widget.title : 'Trò chuyện',
              ),
              actions: [
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: () =>
                      context.read<ChatRoomCubit>().refreshMessages(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: Column(
              children: [
                if (state.isReconnecting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: Colors.amber.shade100,
                    child: const Text(
                      'Đang kết nối lại realtime...',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.errorMessage != null &&
                            state.errorMessage!.isNotEmpty &&
                            state.messages.isEmpty
                      ? AppErrorView(
                          message: state.errorMessage!,
                          onRetry: () =>
                              context.read<ChatRoomCubit>().refreshMessages(),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<ChatRoomCubit>().refreshMessages(),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final mySenderId = state.mySenderId?.trim();
                              final isMine =
                                  mySenderId != null && mySenderId.isNotEmpty
                                  ? message.senderId == mySenderId
                                  : message.senderType == state.mySenderType;

                              return Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.78,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? const Color(0xFFDFF3FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (message.messageText != null &&
                                          message.messageText!.isNotEmpty)
                                        Text(message.messageText!),
                                      if (message.imageUrl != null &&
                                          message.imageUrl!.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top:
                                                message.messageText != null &&
                                                    message
                                                        .messageText!
                                                        .isNotEmpty
                                                ? 8
                                                : 0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              _resolveImageUrl(
                                                message.imageUrl!,
                                              ),
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    width: 180,
                                                    height: 70,
                                                    color: Colors.grey.shade200,
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      'Không tải được ảnh',
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      if (message.sentAt != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Text(
                                            _formatTime(message.sentAt!),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Gửi ảnh',
                          onPressed: state.isSending
                              ? null
                              : () => _showImagePickerOptions(context),
                          icon: const Icon(Icons.image_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _send(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: state.isSending
                              ? null
                              : () => _send(context),
                          icon: state.isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _send(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatRoomCubit>().sendMessage(text);
    _textController.clear();
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile == null || !context.mounted) {
      return;
    }

    await context.read<ChatRoomCubit>().sendImage(File(pickedFile.path));
  }

  String _resolveImageUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }

    if (!uri.hasScheme) {
      return '${AppConfig.imageBaseUrl}${value.startsWith('/') ? '' : '/'}$value';
    }

    if (uri.path.startsWith('/uploads/')) {
      return '${AppConfig.imageBaseUrl}${uri.path}';
    }

    return value;
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
