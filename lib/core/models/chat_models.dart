class ChatConversation {
  final String conversationId;
  final String stallId;
  final String? tenGianHang;
  final String buyerId;
  final String? tenNguoiMua;
  final String? tinNhanCuoi;
  final DateTime? thoiGianCuoi;
  final int unread;

  const ChatConversation({
    required this.conversationId,
    required this.stallId,
    required this.buyerId,
    this.tenGianHang,
    this.tenNguoiMua,
    this.tinNhanCuoi,
    this.thoiGianCuoi,
    this.unread = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      conversationId: (json['conversation_id'] ?? '').toString(),
      stallId: (json['stall_id'] ?? '').toString(),
      tenGianHang: json['ten_gian_hang']?.toString(),
      buyerId: (json['buyer_id'] ?? '').toString(),
      tenNguoiMua: json['ten_nguoi_mua']?.toString(),
      tinNhanCuoi: json['tin_nhan_cuoi']?.toString(),
      thoiGianCuoi: _parseDateTime(json['thoi_gian_cuoi']),
      unread: _parseInt(json['unread']),
    );
  }

  String getDisplayName(String role) {
    return role == 'nguoi_mua'
        ? (tenGianHang?.isNotEmpty == true ? tenGianHang! : stallId)
        : (tenNguoiMua?.isNotEmpty == true ? tenNguoiMua! : buyerId);
  }
}

class ChatMessageModel {
  final int messageId;
  final String senderId;
  final String senderType;
  final String? messageText;
  final String? imageUrl;
  final bool isRead;
  final DateTime? sentAt;

  const ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderType,
    this.messageText,
    this.imageUrl,
    this.isRead = false,
    this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: _parseInt(json['message_id']),
      senderId: (json['sender_id'] ?? '').toString(),
      senderType: (json['sender_type'] ?? '').toString(),
      messageText: json['message_text']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isRead: json['is_read'] == true,
      sentAt: _parseDateTime(json['sent_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message_text': messageText,
      'image_url': imageUrl,
      'is_read': isRead,
      'sent_at': sentAt?.toIso8601String(),
    };
  }
}

class ChatMessagePage {
  final List<ChatMessageModel> messages;
  final int page;
  final int limit;
  final int total;

  const ChatMessagePage({
    required this.messages,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ChatMessagePage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();

    final meta = (json['meta'] as Map<String, dynamic>?) ?? {};

    return ChatMessagePage(
      messages: data,
      page: _parseInt(meta['page'], fallback: 1),
      limit: _parseInt(meta['limit'], fallback: 20),
      total: _parseInt(meta['total']),
    );
  }
}

class ChatCreateConversationResponse {
  final String conversationId;
  final String stallId;
  final String? tenGianHang;
  final String buyerId;

  const ChatCreateConversationResponse({
    required this.conversationId,
    required this.stallId,
    required this.buyerId,
    this.tenGianHang,
  });

  factory ChatCreateConversationResponse.fromJson(Map<String, dynamic> json) {
    return ChatCreateConversationResponse(
      conversationId: (json['conversation_id'] ?? '').toString(),
      stallId: (json['stall_id'] ?? '').toString(),
      tenGianHang: json['ten_gian_hang']?.toString(),
      buyerId: (json['buyer_id'] ?? '').toString(),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
