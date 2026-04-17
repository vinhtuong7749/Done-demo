import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/chat_models.dart';
import 'auth/simple_auth_helper.dart';

class ChatService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<ChatCreateConversationResponse> createConversation(String stallId) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng chat');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$stallId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final jsonData = _decodeResponse(response);
    if (response.statusCode == 200 && jsonData['success'] == true) {
      return ChatCreateConversationResponse.fromJson(jsonData);
    }

    throw Exception(_extractErrorMessage(jsonData, fallback: 'Không thể tạo cuộc trò chuyện'));
  }

  Future<List<ChatConversation>> getConversations() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng chat');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final jsonData = _decodeResponse(response);
    if (response.statusCode == 200 && jsonData['success'] == true) {
      final list = (jsonData['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
      return list;
    }

    throw Exception(_extractErrorMessage(jsonData, fallback: 'Không thể tải danh sách hội thoại'));
  }

  Future<ChatMessagePage> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng chat');
    }

    final uri = Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final jsonData = _decodeResponse(response);
    if (response.statusCode == 200 && jsonData['success'] == true) {
      return ChatMessagePage.fromJson(jsonData);
    }

    throw Exception(_extractErrorMessage(jsonData, fallback: 'Không thể tải tin nhắn'));
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId, {
    String? messageText,
    String? imageUrl,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để sử dụng chat');
    }

    final body = <String, dynamic>{
      if (messageText != null && messageText.trim().isNotEmpty) 'message_text': messageText.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'image_url': imageUrl.trim(),
    };

    if (body.isEmpty) {
      throw Exception('Nội dung tin nhắn không được để trống');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final jsonData = _decodeResponse(response);
    if (response.statusCode == 200 && jsonData['success'] == true) {
      final data = (jsonData['data'] as Map<String, dynamic>? ?? {});
      return ChatMessageModel.fromJson(data);
    }

    throw Exception(_extractErrorMessage(jsonData, fallback: 'Không thể gửi tin nhắn'));
  }

  Future<String> getCurrentRole() async {
    final role = await getUserRole();
    return role ?? 'nguoi_mua';
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [CHAT] Decode response failed: $e');
      return <String, dynamic>{};
    }
  }

  String _extractErrorMessage(Map<String, dynamic> jsonData, {required String fallback}) {
    return (jsonData['message'] ?? jsonData['detail'] ?? fallback).toString();
  }
}
