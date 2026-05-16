import 'package:flutter/material.dart';

// thank you screen after checkout (no real payment in this project)
class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final double totalAmount;
  final int itemCount;
  final String shippingSummary;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.itemCount,
    required this.shippingSummary,
  });

  static const Color bgColor = Color(0xFFeef9fa);
  static const Color teal = Color(0xFF6ecdd4);
  static const Color rose = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 6 ? orderId.substring(0, 6).toUpperCase() : orderId.toUpperCase();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Order Confirmed', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: teal.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: torquoise, size: 72),
                  const SizedBox(height: 16),
                  const Text('Thank you!', style: TextStyle(fontFamily: 'DynaPuff', fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    'Your order #$shortId is confirmed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _row('Items', '$itemCount'),
                  _row('Total', '\$${totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ship to: $shippingSummary',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Demo checkout: no real card was charged. Track status anytime under My Orders.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: rose,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Continue Shopping', style: TextStyle(color: Colors.white, fontFamily: 'DynaPuff', fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: torquoise)),
        ],
      ),
    );
  }
}
