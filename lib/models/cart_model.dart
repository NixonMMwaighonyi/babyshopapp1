import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Shared data shapes for the shop: products, cart, orders, and reviews.

/// Catalog item from Firestore `products` — includes display icon/color by category.
class Product {
  final String id;
  final String title;
  final String price;
  final double priceValue;
  final String description;
  final String category;
  final String brand;
  final String sellerName;
  final double sellerRating;
  final int sellerReviewCount;
  final String imageUrl;
  final int stock;
  double rating;
  int reviewCount;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.priceValue,
    required this.description,
    required this.category,
    this.brand = '',
    this.sellerName = 'BabyShopHub Official',
    this.sellerRating = 4.8,
    this.sellerReviewCount = 0,
    this.imageUrl = '',
    this.stock = 10,
    this.rating = 4.0,
    this.reviewCount = 0,
  });

  IconData get icon => _iconForCategory(category);
  Color get color => _colorForCategory(category);

  static IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'newborn essentials': return Icons.child_care;
      case 'clothing': return Icons.checkroom;
      case 'clothing & shoes': return Icons.checkroom;
      case 'toys': return Icons.toys;
      case 'toys & learning': return Icons.toys;
      case 'feeding': return Icons.local_drink;
      case 'diapering': return Icons.baby_changing_station;
      case 'bath & skincare': return Icons.bathtub_outlined;
      case 'bedding': return Icons.bed;
      case 'nursery & bedding': return Icons.bed;
      case 'diapers': return Icons.baby_changing_station;
      case 'strollers & gear': return Icons.stroller;
      case 'health & safety': return Icons.health_and_safety_outlined;
      default: return Icons.child_friendly;
    }
  }

  static Color _colorForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'newborn essentials': return const Color(0xFF9ccdd4);
      case 'clothing': return const Color(0xFFf79c81);
      case 'clothing & shoes': return const Color(0xFFf79c81);
      case 'toys': return const Color(0xFF6ecdd4);
      case 'toys & learning': return const Color(0xFF6ecdd4);
      case 'feeding': return const Color(0xFF2e9fb4);
      case 'diapering': return const Color(0xFFffe082);
      case 'bath & skincare': return const Color(0xFF90caf9);
      case 'bedding': return const Color(0xFFa5d6a7);
      case 'nursery & bedding': return const Color(0xFFa5d6a7);
      case 'diapers': return const Color(0xFFffe082);
      case 'strollers & gear': return const Color(0xFFb39ddb);
      case 'health & safety': return const Color(0xFF80cbc4);
      default: return const Color(0xFF6ecdd4);
    }
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final priceVal = (data['priceValue'] as num?)?.toDouble() ?? 0.0;
    return Product(
      id: doc.id,
      title: data['title'] ?? 'Unknown Product',
      price: '\$${priceVal.toStringAsFixed(2)}',
      priceValue: priceVal,
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      brand: (data['brand'] ?? '').toString(),
      sellerName: (data['sellerName'] ?? 'BabyShopHub Official').toString(),
      sellerRating: (data['sellerRating'] as num?)?.toDouble() ?? 4.8,
      sellerReviewCount: data['sellerReviewCount'] as int? ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      stock: ((data['stock'] as num?)?.toInt()) ?? 10,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'priceValue': priceValue,
    'description': description,
    'category': category,
    'brand': brand,
    'sellerName': sellerName,
    'sellerRating': sellerRating,
    'sellerReviewCount': sellerReviewCount,
    'imageUrl': imageUrl,
    'stock': stock,
    'rating': rating,
    'reviewCount': reviewCount,
  };
}

/// Customer review on a product (subcollection `products/{id}/reviews`).
class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({this.id = '', required this.userName, required this.rating, required this.comment, required this.date});

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      comment: data['comment'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Rating for the seller listing on a product page.
class SellerReview {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  SellerReview({this.id = '', required this.userName, required this.rating, required this.comment, required this.date});

  factory SellerReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerReview(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      comment: data['comment'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// One line in the in-memory cart (quantity capped by product stock).
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get totalPrice => product.priceValue * quantity;
}

/// Snapshot of a purchased line stored inside an `orders` document.
class OrderItem {
  final String productId;
  final String productTitle;
  final double priceValue;
  final int quantity;

  OrderItem({required this.productId, required this.productTitle, required this.priceValue, required this.quantity});

  Map<String, dynamic> toMap() => {
    'productId': productId, 'productTitle': productTitle, 'priceValue': priceValue, 'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] ?? '',
    productTitle: map['productTitle'] ?? '',
    priceValue: (map['priceValue'] as num?)?.toDouble() ?? 0.0,
    quantity: map['quantity'] as int? ?? 1,
  );
}

/// Customer order — status is updated by admins (Processing → Delivered, etc.).
class AppOrder {
  final String id;
  final String userId;
  final String userEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime date;
  String status;
  final String shippingAddress;

  AppOrder({required this.id, required this.userId, required this.userEmail, required this.items, required this.totalAmount, required this.date, this.status = 'Processing', this.shippingAddress = ''});

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppOrder(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: (data['items'] as List<dynamic>? ?? []).map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Processing',
      shippingAddress: data['shippingAddress'] ?? '',
    );
  }
}

/// In-memory cart for the session; provided at app root via Provider.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void addToCart(Product product) {
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      if (existing.first.quantity < product.stock) {
        existing.first.quantity++;
      }
    } else {
      if (product.stock > 0) {
        _items.add(CartItem(product: product));
      }
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
    } else {
      final item = _items.firstWhere((i) => i.product.id == productId);
      item.quantity = quantity > item.product.stock ? item.product.stock : quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}