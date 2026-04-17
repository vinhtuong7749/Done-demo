class LlmChatHistoryItem {
  final String role;
  final String content;

  const LlmChatHistoryItem({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class LlmDishSuggestion {
  final String title;
  final String? description;
  final Map<String, dynamic> raw;

  const LlmDishSuggestion({
    required this.title,
    this.description,
    required this.raw,
  });

  factory LlmDishSuggestion.fromJson(Map<String, dynamic> json) {
    return LlmDishSuggestion(
      title: (json['dish_name'] ?? json['ten_mon_an'] ?? json['title'] ?? 'Món ăn').toString(),
      description: (json['mo_ta'] ?? json['description'])?.toString(),
      raw: json,
    );
  }
}

class LlmShopSuggestion {
  final String name;
  final String? location;
  final Map<String, dynamic> raw;

  const LlmShopSuggestion({
    required this.name,
    this.location,
    required this.raw,
  });

  factory LlmShopSuggestion.fromJson(Map<String, dynamic> json) {
    return LlmShopSuggestion(
      name: (json['stall_name'] ?? json['ten_gian_hang'] ?? json['name'] ?? 'Gian hàng').toString(),
      location: (json['stall_location'] ?? json['vi_tri'] ?? json['location'])?.toString(),
      raw: json,
    );
  }
}

class LlmChatResponse {
  final String sessionId;
  final String intent;
  final String reply;
  final List<LlmDishSuggestion> dishes;
  final List<LlmShopSuggestion> shops;
  final int totalFound;

  const LlmChatResponse({
    required this.sessionId,
    required this.intent,
    required this.reply,
    required this.dishes,
    required this.shops,
    required this.totalFound,
  });

  factory LlmChatResponse.fromJson(Map<String, dynamic> json) {
    final dishesJson = (json['dishes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final shopsJson = (json['shops'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return LlmChatResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString(),
      reply: (json['reply'] ?? '').toString(),
      dishes: dishesJson.map(LlmDishSuggestion.fromJson).toList(),
      shops: shopsJson.map(LlmShopSuggestion.fromJson).toList(),
      totalFound: _parseInt(json['total_found']),
    );
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
