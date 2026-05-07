import 'package:flutter/material.dart';

class ReviewWidget extends StatelessWidget {
  final String username;
  final double rating;
  final String comment;
  final bool isAdmin; // To show 'Delete' or 'Reply' buttons to admin

  const ReviewWidget({
    super.key,
    required this.username,
    required this.rating,
    required this.comment,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) => Icon(
                      Icons.star,
                      size: 16,
                      color: index < rating ? Colors.amber : Colors.grey[300]
                  )),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(comment),
            if (isAdmin) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () {}, child: const Text("Reply")),
                  TextButton(
                      onPressed: () {},
                      child: const Text("Delete", style: TextStyle(color: Colors.red))
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}