import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final MapController _mapController = MapController();
  LatLng? _shipperLocation;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final url = 'https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app/tracking/${widget.orderId}.json';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200 && response.body != 'null') {
        final data = jsonDecode(response.body);
        if (data != null && data['lat'] != null && data['lng'] != null) {
          final newLoc = LatLng(data['lat'], data['lng']);
          
          // Kiểm tra nếu component còn mount mới gọi setState
          if (!mounted) return;

          setState(() {
            _shipperLocation = newLoc;
            _isLoading = false;
          });
          
          // Tự động di chuyển camera đến shipper
          _mapController.move(newLoc, 16.0);
        }
      } else {
        // Có thể Shipper chưa bắt đầu hoặc chưa có tọa độ
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chợ Bắc Mỹ An
    final defaultLocation = const LatLng(16.039601, 108.242308);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi Shipper'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _shipperLocation ?? defaultLocation,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dngo.buyer',
                ),
                MarkerLayer(
                  markers: [
                    if (_shipperLocation != null)
                      Marker(
                        point: _shipperLocation!,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
