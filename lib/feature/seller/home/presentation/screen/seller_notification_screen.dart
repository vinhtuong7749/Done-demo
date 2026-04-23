import 'package:flutter/material.dart';
import '../../../../../core/services/seller_notification_service.dart';

class SellerNotificationScreen extends StatefulWidget {
  const SellerNotificationScreen({super.key});

  @override
  State<SellerNotificationScreen> createState() => _SellerNotificationScreenState();
}

class _SellerNotificationScreenState extends State<SellerNotificationScreen> {
  final _service = SellerNotificationService();
  List<SellerNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final items = await _service.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(SellerNotification noti) async {
    if (noti.isRead) return;
    await _service.markAsRead(noti.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF26CD3A)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF26CD3A)))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: const Color(0xFF26CD3A),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) => _buildNotiCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF26CD3A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 50, color: Color(0xFF26CD3A)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có thông báo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo về đơn hàng\nsẽ xuất hiện ở đây',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotiCard(SellerNotification noti) {
    final icon = _getIcon(noti.type);
    final color = _getColor(noti.type);

    return GestureDetector(
      onTap: () => _markRead(noti),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: noti.isRead ? Colors.white : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: noti.isRead ? const Color(0xFFE5E7EB) : const Color(0xFF26CD3A).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          noti.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: noti.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (!noti.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF26CD3A), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti.message,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(noti.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order': return Icons.receipt_long_rounded;
      case 'payment': return Icons.payments_rounded;
      case 'warning': return Icons.warning_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order': return const Color(0xFF2E7D32);
      case 'payment': return const Color(0xFF1565C0);
      case 'warning': return const Color(0xFFE65100);
      default: return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
