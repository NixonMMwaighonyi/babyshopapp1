import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:flutter/material.dart';

// order status steps - updates when admin changes status
class TrackOrderScreen extends StatelessWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  static const Color bgColor = Color(0xFFeef9fa);
  static const Color rose = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  static int _statusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 0;
      case 'confirmed':
        return 1;
      case 'shipped':
        return 2;
      case 'delivered':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Track #${(orderId.length >= 6 ? orderId.substring(0, 6) : orderId).toUpperCase()}',
          style: const TextStyle(fontFamily: 'DynaPuff', fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<AppOrder?>(
        stream: ProductService().orderStream(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6ecdd4)));
          }
          final order = snap.data;
          if (order == null) {
            return const Center(child: Text('Order not found or you may not have access.'));
          }

          final idx = _statusIndex(order.status);
          final cancelled = idx < 0;
          const steps = ['Order placed', 'Confirmed', 'Shipped', 'Delivered'];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (cancelled)
                Card(
                  color: Colors.red[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const ListTile(
                    leading: Icon(Icons.cancel_outlined, color: Colors.red),
                    title: Text('This order was cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Contact support if you believe this is a mistake.'),
                  ),
                )
              else
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery progress', style: TextStyle(fontFamily: 'DynaPuff', fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          'Updates appear here automatically when our team changes your order status.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(steps.length, (i) {
                          final done = i <= idx;
                          final active = i == idx;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: done ? torquoise : Colors.grey[300],
                                        border: active ? Border.all(color: rose, width: 2) : null,
                                      ),
                                      child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                    ),
                                    if (i < steps.length - 1)
                                      Container(width: 2, height: 28, color: done ? torquoise.withOpacity(0.35) : Colors.grey[300]),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          steps[i],
                                          style: TextStyle(
                                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                            color: done ? Colors.black87 : Colors.grey,
                                          ),
                                        ),
                                        if (active)
                                          Text('Current step', style: TextStyle(fontSize: 12, color: rose)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Order details', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: torquoise.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(order.status, style: const TextStyle(color: torquoise, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Placed: ${order.date.day}/${order.date.month}/${order.date.year}', style: TextStyle(color: Colors.grey[700])),
                      Text('Total: \$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: torquoise, fontWeight: FontWeight.w600)),
                      if (order.shippingAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Shipping: ${order.shippingAddress}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                      const Divider(height: 24),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.productTitle} ×${item.quantity}')),
                              Text('\$${(item.priceValue * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
