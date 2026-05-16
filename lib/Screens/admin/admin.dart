// Admin dashboard: orders, inventory, feedback, and user management tabs.
import 'package:babyshopapp/Screens/admin/feedbackSupport.dart';
import 'package:babyshopapp/Screens/home/productDetail.dart';
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

String _formatUserFirestoreTime(dynamic v) {
  if (v is Timestamp) {
    final d = v.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '—';
}

/// Bottom navigation across order monitoring, products, support, and users.
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
    _UserManagementPage(),
  ];

  @override
  void initState() {
    super.initState();
    ProductService().ensureDefaultStockForExistingProducts();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      AuthService().recordLastActive(uid);
    }
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
                            : _currentIndex == 2
                                ? 'Feedback Inbox'
                                : 'User Directory',
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: torquoise,
        unselectedItemColor: teal.withOpacity(0.6),
        backgroundColor: Colors.white,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Feedback'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Users'),
        ],
      ),
    );
  }
}

// ── Order Monitoring ─────────────────────────────────────────────────────────
/// Live `orders` list — change status so customers see updates on Track delivery.
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
/// Add/edit/delete products and seed sample catalog items.
class _InventoryPage extends StatelessWidget {
  const _InventoryPage();

  static const Color teal      = Color(0xFF6ecdd4);
  static const Color rose      = Color(0xFFf79c81);
  static const Color torquoise = Color(0xFF2e9fb4);

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final sellerCtrl = TextEditingController(text: 'BabyShopHub Official');
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
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: sellerCtrl, decoration: const InputDecoration(labelText: 'Seller name', border: OutlineInputBorder())),
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
                initialValue: selectedCat,
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
                  brand: brandCtrl.text.trim(),
                  sellerName: sellerCtrl.text.trim().isEmpty ? 'BabyShopHub Official' : sellerCtrl.text.trim(),
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
                                  errorBuilder: (_, _, _) =>
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

// Admin tab: browse Firestore `users`, change roles, open support threads, delete profiles.
class _UserManagementPage extends StatefulWidget {
  const _UserManagementPage();

  @override
  State<_UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<_UserManagementPage> {
  static const Color teal = Color(0xFF6ecdd4);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color rose = Color(0xFFf79c81);

  final _emailLookupCtrl = TextEditingController();
  bool _lookupBusy = false;

  @override
  void dispose() {
    _emailLookupCtrl.dispose();
    super.dispose();
  }

  /// Debug helper when someone exists in Auth but not in the users list yet.
  Future<void> _lookupEmail() async {
    final q = _emailLookupCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _lookupBusy = true);
    final row = await AuthService().getUserProfileByEmail(q);
    if (!mounted) return;
    setState(() => _lookupBusy = false);
    if (row == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No profile in database'),
          content: Text(
            'There is no document in Firestore "users" for:\n$q\n\n'
            'Firebase Authentication accounts do not appear here until the app creates a '
            'user profile (usually right after Register, or on first login for older accounts). '
            'Ask the customer to log in once in BabyShopHub, or add a users/{uid} document in the Firebase console.',
            style: const TextStyle(height: 1.35),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }
    final uid = row['uid'] ?? '';
    final name = (row['name'] ?? '').toString();
    final role = (row['role'] ?? 'customer').toString();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile found'),
        content: Text('Email: ${row['email']}\nName: ${name.isEmpty ? '—' : name}\nRole: $role\nUID: $uid'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _openUserInquiries(BuildContext context, String email) {
    if (email.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Inquiries · $email', style: const TextStyle(fontFamily: 'DynaPuff', fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: FeedbackSupportPage(filterUserEmail: email),
        ),
      ),
    );
  }

  /// Firestore row only — Auth login must be removed in Firebase console if needed.
  Future<void> _confirmAndDeleteUserProfile(
    BuildContext context, {
    required String uid,
    required String email,
    required String? adminUid,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'Remove the Firestore profile for:\n$email\n\n'
          'They will disappear from this list and lose saved profile data in the app.\n\n'
          'Their Firebase Authentication account is not deleted from here. To fully remove login '
          'or free the email, delete the user under Authentication in the Firebase console, or add a Cloud Function with the Admin SDK.',
          style: const TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: rose),
            child: const Text('Delete profile'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await AuthService().deleteUserProfileDocument(uid, adminUid: adminUid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Profile removed from database.'
              : 'Could not delete (check Firestore rules allow admin delete on users/{id}).',
        ),
        backgroundColor: ok ? torquoise : rose,
      ),
    );
  }

  void _showUserAccountDialog(BuildContext context, Map<String, dynamic> u) {
    final email = (u['email'] ?? '').toString();
    final phone = (u['phone'] ?? '').toString();
    final address = (u['address'] ?? '').toString();
    final pm = u['paymentMethods'];
    final pmCount = pm is List ? pm.length : 0;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account', style: TextStyle(fontFamily: 'DynaPuff')),
        content: SingleChildScrollView(
          child: SelectableText(
            'Email: $email\n'
            'Name: ${u['name'] ?? '—'}\n'
            'Role: ${u['role'] ?? '—'}\n'
            'Phone: ${phone.isEmpty ? '—' : phone}\n'
            'Address: ${address.isEmpty ? '—' : address}\n'
            'Saved payment methods (demo): $pmCount\n'
            'Created: ${_formatUserFirestoreTime(u['createdAt'])}\n'
            'Last login: ${_formatUserFirestoreTime(u['lastLoginAt'])}\n'
            'Last active: ${_formatUserFirestoreTime(u['lastActiveAt'])}\n'
            'UID: ${u['uid']}',
            style: const TextStyle(height: 1.45),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUserInquiries(context, email);
            },
            child: const Text('Open inquiries'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Block deleting or demoting yourself by accident.
    final selfUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            color: const Color(0xFFeef9fa),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: teal.withOpacity(0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: torquoise),
                      const SizedBox(width: 8),
                      Text('User management', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[900])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Each row is a Firestore "users" profile. The role menu grants Admin (this dashboard) or Customer (shop).\n'
                    '• Activity: Last login is saved at sign-in; last active updates when someone opens the shop or this admin app.\n'
                    '• Inquiries: Use ⋮ on a row → Support inquiries to read or reply to that customer\'s feedback (same as Feedback tab, filtered).\n'
                    '• Role changes apply after that person signs out and signs in again. You cannot change your own role here.\n'
                    '• Delete profile (⋮) removes their Firestore users row only; use the Firebase console Authentication tab to remove the login if needed.',
                    style: TextStyle(height: 1.4, fontSize: 13, color: Colors.grey[850]),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Look up by email', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailLookupCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'e.g. trevormiles2000m@gmail.com',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _lookupBusy ? null : _lookupEmail,
                        style: FilledButton.styleFrom(backgroundColor: torquoise),
                        child: _lookupBusy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Check'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AuthService().allUsersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6ecdd4)));
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: rose.withOpacity(0.85)),
                        const SizedBox(height: 12),
                        const Text('Could not load users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}\n\n'
                          'Firestore rules must allow admins to read the whole "users" collection. '
                          'If rules only allow each user to read their own document, this list will fail.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                );
              }
              var users = List<Map<String, dynamic>>.from(snap.data ?? []);
              users.sort((a, b) => (a['email'] ?? '').toString().compareTo((b['email'] ?? '').toString()));

              if (users.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_outlined, size: 72, color: teal.withOpacity(0.45)),
                        const SizedBox(height: 16),
                        const Text('No rows in Firestore "users"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 12),
                        Text(
                          'This screen lists Cloud Firestore profiles (collection users), not the Authentication user list.\n\n'
                          '• After someone taps Register in the app, a users/{uid} document should be created.\n'
                          '• If the account was made only in the Firebase console under Authentication, there may be no users document yet — have them open the app and log in once.\n'
                          '• If Firestore security rules block listing users, fix rules so admins can read users (see error above if the load failed).',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.4, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = users[i];
                  final uid = u['uid']?.toString() ?? '';
                  final email = (u['email'] ?? '').toString();
                  final name = (u['name'] ?? '').toString().trim();
                  final role = (u['role'] ?? 'customer').toString();
                  final isSelf = uid.isNotEmpty && uid == selfUid;

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 0.5,
                    child: ListTile(
                      isThreeLine: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: torquoise.withOpacity(0.15),
                        child: Text(
                          (name.isNotEmpty ? name : email).isNotEmpty ? (name.isNotEmpty ? name : email)[0].toUpperCase() : '?',
                          style: const TextStyle(color: torquoise, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name.isNotEmpty ? name : email, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (name.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12)),
                          Text('UID: ${uid.length > 8 ? uid.substring(0, 8) : uid}…', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            'Joined ${_formatUserFirestoreTime(u['createdAt'])} · '
                            'Login ${_formatUserFirestoreTime(u['lastLoginAt'])} · '
                            'Active ${_formatUserFirestoreTime(u['lastActiveAt'])}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF2e9fb4)),
                            onSelected: (value) {
                              if (value == 'details') {
                                _showUserAccountDialog(context, u);
                              } else if (value == 'inquiries') {
                                _openUserInquiries(context, email);
                              } else if (value == 'delete') {
                                _confirmAndDeleteUserProfile(context, uid: uid, email: email, adminUid: selfUid);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'details', child: Text('Account details')),
                              const PopupMenuItem(value: 'inquiries', child: Text('Support inquiries')),
                              PopupMenuItem(
                                value: 'delete',
                                enabled: !isSelf,
                                child: Text('Delete profile…', style: TextStyle(color: isSelf ? Colors.grey : rose)),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 118,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: role == 'admin' ? 'admin' : 'customer',
                                isExpanded: true,
                                icon: const Icon(Icons.expand_more, color: torquoise),
                                items: const [
                                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: isSelf
                                    ? null
                                    : (v) async {
                                        if (v == null || v == role) return;
                                        final ok = await AuthService().setUserRole(uid, v);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? 'Role updated to $v. They should sign out and sign in again to see it.'
                                                  : 'Could not update role (check Firestore rules).',
                                            ),
                                            backgroundColor: ok ? torquoise : rose,
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
