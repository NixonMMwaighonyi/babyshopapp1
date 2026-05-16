import 'package:flutter/material.dart';
import 'package:babyshopapp/services/productService.dart';

/// Admin inbox for profile “Contact Support” messages; optional filter by customer email.
class FeedbackSupportPage extends StatelessWidget {
  /// When set, only feedback rows whose [userEmail] matches (case-insensitive).
  final String? filterUserEmail;

  const FeedbackSupportPage({super.key, this.filterUserEmail});

  static const Color teal = Color(0xFF6ecdd4);
  static const Color rose = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color darkGrey = Color(0xFF575757);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProductService().feedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: teal));
        }

        var feedbackItems = List<Map<String, dynamic>>.from(snapshot.data ?? []);
        final filter = filterUserEmail?.trim().toLowerCase();
        if (filter != null && filter.isNotEmpty) {
          feedbackItems = feedbackItems
              .where((e) => (e['userEmail'] ?? '').toString().toLowerCase() == filter)
              .toList();
        }

        if (feedbackItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 72, color: teal.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  filter != null && filter.isNotEmpty
                      ? 'No support messages from this email yet'
                      : 'No customer feedback yet',
                  style: const TextStyle(fontFamily: 'DynaPuff', fontSize: 16, color: darkGrey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: feedbackItems.length,
          itemBuilder: (context, index) {
            final item = feedbackItems[index];
            final email = (item['userEmail'] ?? 'Unknown').toString();
            final message = (item['message'] ?? '').toString();
            final reply = (item['reply'] ?? '').toString();
            final resolved = item['resolved'] == true;

            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: resolved ? teal.withOpacity(0.18) : rose.withOpacity(0.18),
                  child: Icon(
                    resolved ? Icons.check_circle_outline : Icons.mark_email_unread_outlined,
                    color: resolved ? torquoise : rose,
                  ),
                ),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'InterNormal'),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message, style: const TextStyle(color: darkGrey)),
                      if (reply.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Reply: $reply', style: const TextStyle(color: torquoise, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.reply_outlined, color: torquoise),
                  onPressed: () => _showReplyDialog(context, item['id'].toString()),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReplyDialog(BuildContext context, String feedbackId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reply to Customer", style: TextStyle(fontFamily: 'DynaPuff')),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Type your response here...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: torquoise),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await ProductService().replyToFeedback(feedbackId, controller.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reply sent to customer!"), backgroundColor: torquoise),
              );
            },
            child: const Text("Send Reply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
