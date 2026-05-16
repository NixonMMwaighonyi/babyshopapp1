// Product page: add to cart, product reviews, seller reviews; admins can edit from here too.
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductDetail extends StatefulWidget {
  final Product product;
  final bool isAdmin;

  const ProductDetail({super.key, required this.product, this.isAdmin = false});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  final ProductService _ps = ProductService();
  final _reviewCommentCtrl = TextEditingController();
  final _sellerCommentCtrl = TextEditingController();
  double _reviewRating = 5.0;
  double _sellerReviewRating = 5.0;
  bool _submitting = false;
  bool _sellerSubmitting = false;

  @override
  void dispose() {
    _reviewCommentCtrl.dispose();
    _sellerCommentCtrl.dispose();
    super.dispose();
  }

  void _addToCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addToCart(widget.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.product.title} added to cart!'), backgroundColor: teal),
    );
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Write a Review', style: TextStyle(fontFamily: 'DynaPuff')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(Icons.star, color: i < _reviewRating ? Colors.amber : Colors.grey[300]),
                  onPressed: () => setS(() => _reviewRating = (i + 1).toDouble()),
                )),
              ),
              TextField(
                controller: _reviewCommentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: torquoise),
              onPressed: _submitting ? null : () async {
                if (_reviewCommentCtrl.text.trim().isEmpty) return;
                setS(() => _submitting = true);
                final user = FirebaseAuth.instance.currentUser;
                final userData = user != null ? await AuthService().getUserData(user.uid) : null;
                final name = userData?['name'] ?? user?.email ?? 'Anonymous';
                await _ps.addReview(widget.product.id, Review(
                  userName: name,
                  rating: _reviewRating,
                  comment: _reviewCommentCtrl.text.trim(),
                  date: DateTime.now(),
                ));
                _reviewCommentCtrl.clear();
                setS(() => _submitting = false);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellerReviewDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Rate seller', style: TextStyle(fontFamily: 'DynaPuff')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience with ${widget.product.sellerName}?', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(Icons.star, color: i < _sellerReviewRating ? Colors.amber : Colors.grey[300]),
                    onPressed: () => setS(() => _sellerReviewRating = (i + 1).toDouble()),
                  ),
                ),
              ),
              TextField(
                controller: _sellerCommentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Optional comment...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: torquoise),
              onPressed: _sellerSubmitting
                  ? null
                  : () async {
                      setS(() => _sellerSubmitting = true);
                      final user = FirebaseAuth.instance.currentUser;
                      final userData = user != null ? await AuthService().getUserData(user.uid) : null;
                      final name = userData?['name'] ?? user?.email ?? 'Anonymous';
                      final ok = await _ps.addSellerReview(
                        widget.product.id,
                        SellerReview(
                          userName: name,
                          rating: _sellerReviewRating,
                          comment: _sellerCommentCtrl.text.trim(),
                          date: DateTime.now(),
                        ),
                      );
                      _sellerCommentCtrl.clear();
                      setS(() => _sellerSubmitting = false);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'Seller rating saved!' : 'Could not save seller rating.'),
                          backgroundColor: ok ? teal : rose,
                        ),
                      );
                    },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final titleCtrl = TextEditingController(text: widget.product.title);
    final priceCtrl = TextEditingController(text: widget.product.priceValue.toString());
    final descCtrl = TextEditingController(text: widget.product.description);
    final imageCtrl = TextEditingController(text: widget.product.imageUrl);
    final brandCtrl = TextEditingController(text: widget.product.brand);
    final sellerCtrl = TextEditingController(text: widget.product.sellerName);
    final picker = ImagePicker();
    XFile? selectedImage;
    bool uploadingImage = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (\$)'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 8),
                TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
                const SizedBox(height: 8),
                TextField(controller: sellerCtrl, decoration: const InputDecoration(labelText: 'Seller name')),
                const SizedBox(height: 8),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: uploadingImage
                      ? null
                      : () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1400,
                            imageQuality: 85,
                          );
                          if (picked == null) return;

                          setS(() {
                            selectedImage = picked;
                            uploadingImage = true;
                          });

                          final uploaded = await _ps.uploadProductImage(picked.path);
                          if (uploaded != null) imageCtrl.text = uploaded;

                          setS(() {
                            uploadingImage = false;
                          });
                        },
                  icon: const Icon(Icons.photo_library_outlined, color: torquoise),
                  label: Text(
                    uploadingImage ? 'Uploading image...' : 'Replace from gallery',
                    style: const TextStyle(color: torquoise),
                  ),
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(selectedImage!.path),
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploadingImage
                  ? null
                  : () async {
                      await _ps.updateProduct(widget.product.id, {
                        'title': titleCtrl.text.trim(),
                        'priceValue':
                            double.tryParse(priceCtrl.text.trim()) ?? widget.product.priceValue,
                        'description': descCtrl.text.trim(),
                        'imageUrl': imageCtrl.text.trim(),
                        'brand': brandCtrl.text.trim(),
                        'sellerName': sellerCtrl.text.trim().isEmpty
                            ? 'BabyShopHub Official'
                            : sellerCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context); // Go back to inventory
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: torquoise),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.product.title, style: const TextStyle(fontFamily: 'DynaPuff', fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: widget.isAdmin ? [
          IconButton(icon: const Icon(Icons.edit, color: torquoise), onPressed: _showEditDialog),
          IconButton(icon: const Icon(Icons.delete, color: rose), onPressed: () async {
            final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Delete Product'),
              content: const Text('Are you sure you want to delete this product?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
              ],
            ));
            if (confirm == true) {
              await _ps.deleteProduct(widget.product.id);
              if (context.mounted) Navigator.pop(context);
            }
          }),
        ] : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image area
            Container(
              height: 220,
              width: double.infinity,
              color: widget.product.color.withOpacity(0.15),
              child: widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) =>
                          Icon(widget.product.icon, size: 100, color: widget.product.color),
                    )
                  : Icon(widget.product.icon, size: 100, color: widget.product.color),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.product.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      Text(widget.product.price, style: TextStyle(fontSize: 20, color: torquoise, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(' ${widget.product.rating.toStringAsFixed(1)} (${widget.product.reviewCount} reviews)',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: teal.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.product.category, style: TextStyle(color: torquoise, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.product.stock > 0 ? 'Stock: ${widget.product.stock}' : 'Out of stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.product.stock > 0 ? Colors.green : rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  if (widget.product.brand.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Brand: ${widget.product.brand}', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(widget.product.description.isNotEmpty ? widget.product.description : 'No description available.', style: const TextStyle(color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: teal.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Seller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(widget.product.sellerName, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 18, color: torquoise),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.product.sellerRating.toStringAsFixed(1)} · ${widget.product.sellerReviewCount} seller reviews',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        label: Text(
                          widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'DynaPuff'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.product.stock > 0 ? rose : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: widget.product.stock > 0 ? _addToCart : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seller feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          icon: const Icon(Icons.rate_review_outlined, size: 16, color: torquoise),
                          label: const Text('Rate seller', style: TextStyle(color: torquoise, fontSize: 13)),
                          onPressed: _showSellerReviewDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<List<SellerReview>>(
                      stream: _ps.sellerReviewsStream(widget.product.id),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: teal)));
                        }
                        final reviews = snap.data ?? [];
                        if (reviews.isEmpty) {
                          return const Text('No seller reviews yet.', style: TextStyle(color: Colors.grey));
                        }
                        return Column(
                          children: reviews.map((r) => _SellerReviewTile(review: r)).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: torquoise),
                          label: const Text('Write Review', style: TextStyle(color: torquoise, fontSize: 13)),
                          onPressed: _showReviewDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Review>>(
                      stream: _ps.reviewsStream(widget.product.id),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: teal));
                        final reviews = snap.data ?? [];
                        if (reviews.isEmpty) return const Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey));
                        return Column(
                          children: reviews.map((r) => _ReviewTile(review: r)).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerReviewTile extends StatelessWidget {
  final SellerReview review;
  const _SellerReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < review.rating ? Colors.amber : Colors.grey[300]))),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment),
            ],
            const SizedBox(height: 4),
            Text('${review.date.day}/${review.date.month}/${review.date.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < review.rating ? Colors.amber : Colors.grey[300]))),
              ],
            ),
            const SizedBox(height: 6),
            Text(review.comment),
            const SizedBox(height: 4),
            Text('${review.date.day}/${review.date.month}/${review.date.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}