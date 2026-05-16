import 'package:flutter/material.dart';

// help page with common questions
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const Color bgColor = Color(0xFFeef9fa);
  static const Color torquoise = Color(0xFF2e9fb4);

  static const _faqs = <Map<String, String>>[
    {
      'q': 'How do I place an order?',
      'a': 'Browse categories or search, add items to your cart, then open the cart and tap Proceed to Checkout. Fill in shipping details and confirm — payments are simulated in this demo app.',
    },
    {
      'q': 'How can I track my delivery?',
      'a': 'Open My Orders from the bottom bar, expand an order, and tap Track delivery to see the live status timeline as our team updates it.',
    },
    {
      'q': 'How do reviews and seller ratings work?',
      'a': 'On any product page you can leave a product review and rate the seller. Seller scores help other parents choose trusted listings.',
    },
    {
      'q': 'Where are my addresses and payment methods?',
      'a': 'Go to Profile to edit your name, phone, and default address. You can also save dummy payment methods (for example card nickname and last four digits) to mirror a real wallet.',
    },
    {
      'q': 'How do I get help?',
      'a': 'Use Contact Support on your profile to send a message. Admins can reply from the Feedback tab in the admin panel.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Help & FAQ', style: TextStyle(fontFamily: 'DynaPuff')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'BabyShopHub tips',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'These quick answers explain how the app maps to your coursework requirements: shopping, checkout, orders, reviews, admin tools, and support.',
            style: TextStyle(color: Colors.grey[700], height: 1.45),
          ),
          const SizedBox(height: 16),
          ..._faqs.map(
            (f) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                iconColor: torquoise,
                collapsedIconColor: torquoise,
                title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(f['a']!, style: TextStyle(color: Colors.grey[800], height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
