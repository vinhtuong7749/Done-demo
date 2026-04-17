import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/llm_chat_models.dart';

class LlmChatbotService {
  static const String _baseUrl = AppConfig.llmBaseUrl;

  Future<LlmChatResponse> sendMessage({
    required String message,
    String? sessionId,
    List<LlmChatHistoryItem> history = const [],
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      throw Exception('Nội dung tin nhắn không được để trống');
    }

    final body = <String, dynamic>{
      'message': text,
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      'history': history.map((item) => item.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl${AppConfig.llmChatEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final jsonData = _decodeResponse(response);
    if (response.statusCode == 200) {
      return LlmChatResponse.fromJson(jsonData);
    }

    final errorMessage =
      (jsonData['detail'] ?? jsonData['message'] ?? 'Không thể gửi tin nhắn chatbot').toString();
    throw Exception(errorMessage);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [LLM CHATBOT] Decode response failed: $e');
      return <String, dynamic>{};
    }
  }
}
