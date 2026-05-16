// Main shop shell: browse products, cart badge, orders & profile from the bottom bar.
import 'package:babyshopapp/Screens/home/cartScreen.dart';
import 'package:babyshopapp/Screens/home/orderHistory.dart';
import 'package:babyshopapp/Screens/home/productDetail.dart';
import 'package:babyshopapp/Screens/home/profile.dart';
import 'package:babyshopapp/models/cart_model.dart';
import 'package:babyshopapp/services/auth.dart';
import 'package:babyshopapp/services/productService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Customer home with shop tab, orders shortcut, profile, and cart in the app bar.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Brand Colors
  static const Color bgColor    = Color(0xFFeef9fa);
  static const Color teal       = Color(0xFF6ecdd4);
  static const Color rose       = Color(0xFFf79c81);
  static const Color torquoise  = Color(0xFF2e9fb4);
  static const Color darkGrey   = Color(0xFF575757);

  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
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

  final List<Widget> _pages = const [
    _ShopBody(),
    OrderHistoryScreen(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _productService.ensureDefaultStockForExistingProducts();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      AuthService().recordLastActive(uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => index == 1 ? const OrderHistoryScreen() : const Profile()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by name, brand, or category...',
            prefixIcon: const Icon(Icons.search, color: teal),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: teal),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: teal),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: teal, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: torquoise, width: 1.5),
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: darkGrey),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: rose,
                    child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(color: selected ? Colors.white : torquoise, fontSize: 12)),
                    selected: selected,
                    selectedColor: torquoise,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: teal),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          // Product grid
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.productsByCategoryStream(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: teal));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading products', style: TextStyle(color: rose)));
                }
                var products = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery;
                  products = products.where((p) {
                    return p.title.toLowerCase().contains(q) ||
                        p.brand.toLowerCase().contains(q) ||
                        p.category.toLowerCase().contains(q);
                  }).toList();
                }
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.child_friendly, size: 60, color: teal.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('No products found', style: TextStyle(color: darkGrey.withOpacity(0.6))),
                        const SizedBox(height: 4),
                        const Text('The admin can add products from the Inventory tab.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 272,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: rose,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Product grid with search + category chips (used inside [Home] tab 0).
class _ShopBody extends StatelessWidget {
  const _ShopBody();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Tappable grid tile — opens [ProductDetail].
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  static const Color teal     = Color(0xFF6ecdd4);
  static const Color torquoise = Color(0xFF2e9fb4);
  static const Color rose     = Color(0xFFf79c81);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetail(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: teal.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: product.color.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) =>
                              Icon(product.icon, size: 56, color: product.color),
                        ),
                      )
                    : Icon(product.icon, size: 56, color: product.color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      product.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(product.price, style: TextStyle(color: torquoise, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(children: [
                            const Icon(Icons.star, color: Colors.amber, size: 13),
                            Text(' ${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 6),
                            Text(
                              product.stock > 0 ? 'Stock ${product.stock}' : 'Out',
                              style: TextStyle(
                                fontSize: 10,
                                color: product.stock > 0 ? Colors.green : rose,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ),
                        GestureDetector(
                          onTap: product.stock > 0
                              ? () {
                            cart.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${product.title} added to cart'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: teal,
                            ));
                          }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: product.stock > 0 ? rose : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}