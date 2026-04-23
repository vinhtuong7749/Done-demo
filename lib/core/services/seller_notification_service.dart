import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth/simple_auth_helper.dart';

class SellerNotification {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;
  final String type;

  SellerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    required this.type,
  });

  factory SellerNotification.fromJson(Map<String, dynamic> json) {
    return SellerNotification(
      id: (json['id'] ?? json['noti_id'] ?? '').toString(),
      title: json['title'] ?? json['tieu_de'] ?? 'Thông báo',
      message: json['message'] ?? json['noi_dung'] ?? '',
      isRead: json['is_read'] ?? json['da_doc'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? json['thoi_gian'] ?? '') ?? DateTime.now(),
      orderId: json['order_id']?.toString(),
      type: json['type'] ?? 'general',
    );
  }
}

class SellerNotificationService {
  static const String _baseUrl = AppConfig.sellerBaseUrl;

  Future<List<SellerNotification>> getNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📢 [NOTI] Response: ${response.statusCode}');
      debugPrint('📢 [NOTI] Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = body['data'] ?? body ?? [];
        return items
            .whereType<Map<String, dynamic>>()
            .map((e) => SellerNotification.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [NOTI] Error: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String notiId) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/$notiId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [NOTI] Mark read error: $e');
      return false;
    }
  }

  Future<int> getUnreadCount() async {
    final notis = await getNotifications();
    return notis.where((n) => !n.isRead).length;
  }
}
