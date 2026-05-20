import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/cart_model.dart';

/// Firestore + Storage for products, orders, reviews, feedback, and checkout stock updates.
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static bool _stockBackfillRan = false;

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<List<Product>> get allProductsStream => _db
      .collection('products')
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromFirestore(d)).toList());

  Stream<List<Product>> productsByCategoryStream(String category) {
    if (category == 'All') return allProductsStream;
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromFirestore(d)).toList());
  }

  Stream<List<Review>> reviewsStream(String productId) => _db
      .collection('products')
      .doc(productId)
      .collection('reviews')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromFirestore(d)).toList());

  Stream<List<SellerReview>> sellerReviewsStream(String productId) => _db
      .collection('products')
      .doc(productId)
      .collection('seller_reviews')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => SellerReview.fromFirestore(d)).toList());

  // ── Admin CRUD ─────────────────────────────────────────────────────────────
  Future<bool> addProduct({
    required String title,
    required double priceValue,
    required String description,
    required String category,
    String imageUrl = '',
    String brand = '',
    String sellerName = 'BabyShopHub Official',
  }) async {
    try {
      await _db.collection('products').add({
        'title': title,
        'priceValue': priceValue,
        'description': description,
        'category': category,
        'brand': brand,
        'sellerName': sellerName,
        'sellerRating': 4.8,
        'sellerReviewCount': 0,
        'imageUrl': imageUrl,
        'stock': 10,
        'rating': 4.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('products').doc(id).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _db.collection('products').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────
  Future<bool> addReview(String productId, Review review) async {
    try {
      final batch = _db.batch();
      final reviewRef = _db.collection('products').doc(productId).collection('reviews').doc();
      batch.set(reviewRef, {
        'userName': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'date': FieldValue.serverTimestamp(),
      });
      // Recalculate average rating
      final prodDoc = await _db.collection('products').doc(productId).get();
      if (prodDoc.exists) {
        final data = prodDoc.data() as Map<String, dynamic>;
        final currentCount = (data['reviewCount'] as int?) ?? 0;
        final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final newCount = currentCount + 1;
        final newRating = ((currentRating * currentCount) + review.rating) / newCount;
        batch.update(_db.collection('products').doc(productId), {
          'reviewCount': newCount,
          'rating': double.parse(newRating.toStringAsFixed(1)),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSellerReview(String productId, SellerReview review) async {
    try {
      final batch = _db.batch();
      final ref = _db.collection('products').doc(productId).collection('seller_reviews').doc();
      batch.set(ref, {
        'userName': review.userName,
        'rating': review.rating,
        'comment': review.comment,
        'date': FieldValue.serverTimestamp(),
      });
      final prodDoc = await _db.collection('products').doc(productId).get();
      if (prodDoc.exists) {
        final data = prodDoc.data() as Map<String, dynamic>;
        final currentCount = (data['sellerReviewCount'] as int?) ?? 0;
        final currentRating = (data['sellerRating'] as num?)?.toDouble() ?? 4.8;
        final newCount = currentCount + 1;
        final newRating = ((currentRating * currentCount) + review.rating) / newCount;
        batch.update(_db.collection('products').doc(productId), {
          'sellerReviewCount': newCount,
          'sellerRating': double.parse(newRating.toStringAsFixed(1)),
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  Stream<List<AppOrder>> allOrdersStream() => _db
      .collection('orders')
      .snapshots()
      .map((s) {
        final orders = s.docs.map((d) => AppOrder.fromFirestore(d)).toList();
        orders.sort((a, b) => b.date.compareTo(a.date));
        return orders;
      });

  Stream<List<AppOrder>> userOrdersStream(String userId) => _db
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) {
        final orders = s.docs.map((d) => AppOrder.fromFirestore(d)).toList();
        orders.sort((a, b) => b.date.compareTo(a.date));
        return orders;
      });

  Stream<AppOrder?> orderStream(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((s) {
        if (!s.exists) return null;
        return AppOrder.fromFirestore(s);
      });

  /// Checkout: verifies stock, decrements counts, and creates an `orders` document.
  Future<String?> placeOrder({
    required String userId,
    required String userEmail,
    required List<CartItem> cartItems,
    required double totalAmount,
    required String shippingAddress,
  }) async {
    String? newOrderId;
    try {
      await _db.runTransaction((transaction) async {

        // Validate ids and build refs
        final Map<String, DocumentReference> refs = {};
        for (final item in cartItems) {
          if (item.product.id.isEmpty) {
            throw Exception('Invalid product id in cart: ${item.product.title}');
          }
          refs[item.product.id] = _db.collection('products').doc(item.product.id);
        }

        final Map<String, DocumentSnapshot> snaps = {};
        for (final e in refs.entries) {
          snaps[e.key] = await transaction.get(e.value);
          if (!snaps[e.key]!.exists) throw Exception('Product not found: ${e.key}');
        }

        final Map<String, int> required = {};
        for (final item in cartItems) {
          required[item.product.id] = (required[item.product.id] ?? 0) + item.quantity;
        }

        for (final id in required.keys) {
          final data = snaps[id]!.data() as Map<String, dynamic>;
          final stock = ((data['stock'] as num?)?.toInt()) ?? 10;
          if (stock < required[id]!) {
            throw Exception('Insufficient stock for product $id');
          }
        }
        
        for (final id in required.keys) {
          final data = snaps[id]!.data() as Map<String, dynamic>;
          final stock = ((data['stock'] as num?)?.toInt()) ?? 10;
          transaction.update(refs[id]!, {'stock': stock - required[id]!});
        }

        final orderRef = _db.collection('orders').doc();
        newOrderId = orderRef.id;
        transaction.set(orderRef, {
          'userId': userId,
          'userEmail': userEmail,
          'items': cartItems
              .map((i) => OrderItem(
                    productId: i.product.id,
                    productTitle: i.product.title,
                    priceValue: i.product.priceValue,
                    quantity: i.quantity,
                  ).toMap())
              .toList(),
          'totalAmount': totalAmount,
          'shippingAddress': shippingAddress,
          'status': 'Processing',
          'date': FieldValue.serverTimestamp(),
        });
      });
      return newOrderId;
    } catch (e, st) {
      debugPrint('placeOrder failed: $e\n$st');
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection('orders').doc(orderId).update({'status': status});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Feedback ───────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> feedbackStream() => _db
      .collection('feedback')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<bool> submitFeedback({required String userId, required String userEmail, required String message}) async {
    try {
      await _db.collection('feedback').add({
        'userId': userId,
        'userEmail': userEmail,
        'message': message,
        'reply': '',
        'resolved': false,
        'date': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> replyToFeedback(String feedbackId, String reply) async {
    try {
      await _db.collection('feedback').doc(feedbackId).update({'reply': reply, 'resolved': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProductImage(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('products').child(fileName);
      final task = await ref.putFile(file);
      return task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> ensureDefaultStockForExistingProducts() async {
    if (_stockBackfillRan) return;
    _stockBackfillRan = true;
    try {
      final snapshot = await _db.collection('products').get();
      final batch = _db.batch();
      var touched = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('stock')) {
          batch.update(doc.reference, {'stock': 10});
          touched++;
        }
      }
      if (touched > 0) {
        await batch.commit();
      }
    } catch (_) {
      // Ignore backfill failures; app still works with fallback stock.
    }
  }

  // ── Seed sample products (admin only, run once) ────────────────────────────
  Future<void> seedSampleProducts() async {
    final samples = [
      {'title': 'Cotton Onesie', 'priceValue': 15.0, 'description': 'Soft 100% cotton onesie, gentle on sensitive skin. Available in sizes 0–12 months.', 'category': 'Clothing'},
      {'title': 'Rubber Duck', 'priceValue': 5.0, 'description': 'Classic rubber duck for bath time fun. BPA-free and safe for babies.', 'category': 'Toys'},
      {'title': 'Baby Bottle Set (3-pack)', 'priceValue': 18.0, 'description': 'Anti-colic baby bottles with slow-flow nipples. Dishwasher safe.', 'category': 'Feeding'},
      {'title': 'Fleece Blanket', 'priceValue': 22.0, 'description': 'Ultra-soft fleece baby blanket, perfect for keeping your little one cozy.', 'category': 'Bedding'},
      {'title': 'Diapers Pack (50 count)', 'priceValue': 30.0, 'description': 'Ultra-absorbent with wetness indicator. Hypoallergenic and dermatologically tested.', 'category': 'Diapers'},
      {'title': 'Silicone Teething Ring', 'priceValue': 8.0, 'description': 'Soothe sore gums with this food-grade silicone teething ring.', 'category': 'Toys'},
    ];
    for (final p in samples) {
      await _db.collection('products').add({
        ...p,
        'brand': p['title'].toString().split(' ').first,
        'sellerName': 'BabyShopHub Official',
        'sellerRating': 4.8,
        'sellerReviewCount': 0,
        'imageUrl': '',
        'stock': 10,
        'rating': 4.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
