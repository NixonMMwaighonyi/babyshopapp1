import 'package:babyshopapp/Screens/admin/feedbackSupport.dart';
import 'package:babyshopapp/Screens/home/productDetail.dart';
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _currentIndex = 0;
  final AuthService _auth = AuthService();

  static const Color bgColor   = Color(0xFFeef9fa);
  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color darkGrey  = Color(0xFF575757);

  final List<Widget> _pages = const [
    _OrderMonitoringPage(),
    _InventoryPage(),
    FeedbackSupportPage(),
  ];

  @override
  void initState() {
    super.initState();
    ProductService().ensureDefaultStockForExistingProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: darkGrey),
            onPressed: () async => await _auth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: teal.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: torquoise.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dashboard_customize_outlined, color: torquoise),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentIndex == 0
                        ? 'Orders Command Center'
                        : _currentIndex == 1
                            ? 'Inventory Studio'
                            : 'Feedback Inbox',
                    style: const TextStyle(
                      fontFamily: 'DynaPuff',
                      fontSize: 16,
                      color: darkGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: torquoise,
        unselectedItemColor: teal.withOpacity(0.6),
        backgroundColor: Colors.white,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Feedback'),
        ],
      ),
    );
  }
}

// ── Order Monitoring ─────────────────────────────────────────────────────────
class _OrderMonitoringPage extends StatelessWidget {
  const _OrderMonitoringPage();

  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'shipped':   return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  void _showStatusDialog(BuildContext context, AppOrder order) {
    final statuses = ['Processing', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Order #${order.id.substring(0, 6).toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) => RadioListTile<String>(
            title: Text(s),
            value: s, groupValue: order.status,
            activeColor: torquoise,
            onChanged: (v) async {
              await ProductService().updateOrderStatus(order.id, v!);
              if (context.mounted) Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppOrder>>(
      stream: ProductService().allOrdersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF6ecdd4)));
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: teal.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final order = orders[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFeef9fa), child: Icon(Icons.shopping_bag_outlined, color: torquoise)),
                title: Text('Order #${order.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${order.userEmail} · \$${order.totalAmount.toStringAsFixed(2)}'),
                trailing: GestureDetector(
                  onTap: () => _showStatusDialog(context, order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(order.status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(order.status, style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Divider(),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${item.productTitle} x${item.quantity}'),
                          Text('\$${(item.priceValue * item.quantity).toStringAsFixed(2)}', style: TextStyle(color: torquoise)),
                        ]),
                      )),
                      const Divider(),
                      Text('Shipping: ${order.shippingAddress}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Date: ${order.date.day}/${order.date.month}/${order.date.year}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Inventory Management ─────────────────────────────────────────────────────
class _InventoryPage extends StatelessWidget {
  const _InventoryPage();

  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final imageCtrl = TextEditingController();
    final picker = ImagePicker();
    XFile? selectedImage;
    bool isUploadingImage = false;
    String selectedCat = 'Newborn Essentials';
    final cats = [
      'Newborn Essentials',
      'Feeding',
      'Diapering',
      'Bath & Skincare',
      'Nursery & Bedding',
      'Strollers & Gear',
      'Toys & Learning',
      'Health & Safety',
      'Clothing & Shoes',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add New Product', style: TextStyle(fontFamily: 'DynaPuff')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Product Title', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: imageCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isUploadingImage
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
                                isUploadingImage = true;
                              });

                              final uploadedUrl =
                                  await ProductService().uploadProductImage(picked.path);

                              if (uploadedUrl != null) {
                                imageCtrl.text = uploadedUrl;
                              }

                              setS(() {
                                isUploadingImage = false;
                              });
                            },
                      icon: const Icon(Icons.photo_library_outlined, color: torquoise),
                      label: Text(
                        isUploadingImage ? 'Uploading image...' : 'Choose from gallery',
                        style: const TextStyle(color: torquoise),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: torquoise),
                      ),
                    ),
                  ),
                ],
              ),
              if (selectedImage != null) ...[
                const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCat,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => selectedCat = v ?? 'Newborn Essentials'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: torquoise),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                if (isUploadingImage) return;
                await ProductService().addProduct(
                  title: titleCtrl.text.trim(),
                  priceValue: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  description: descCtrl.text.trim(),
                  category: selectedCat,
                  imageUrl: imageCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Product', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeedConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seed Sample Products'),
        content: const Text('This will add 6 sample baby products to your Firestore database. Only do this once.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: torquoise),
            onPressed: () async {
              await ProductService().seedSampleProducts();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample products added!'), backgroundColor: Color(0xFF2e9fb4)));
              }
            },
            child: const Text('Add Samples', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: torquoise,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService().allProductsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF6ecdd4)));
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: teal.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_fix_high, color: torquoise),
                  label: const Text('Add Sample Products', style: TextStyle(color: torquoise)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: torquoise)),
                  onPressed: () => _showSeedConfirm(context),
                ),
              ]),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.82, crossAxisSpacing: 14, mainAxisSpacing: 14),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetail(product: p, isAdmin: true))),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: teal.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: teal.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.color.withOpacity(0.12),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: p.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: Image.network(
                                  p.imageUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(p.icon, size: 50, color: p.color),
                                ),
                              )
                            : Icon(p.icon, size: 50, color: p.color),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(p.price, style: TextStyle(color: torquoise, fontSize: 12)),
                          const Spacer(),
                          Row(children: [
                            const Icon(Icons.inventory_2_outlined, size: 11, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${p.category} · ${p.stock} left',
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
