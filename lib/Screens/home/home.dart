import 'package:babyshopapp/Screens/home/profile.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color BabyBackgroundColor = Color(0xFFeef9fa);
  final Color BabyTeal = Color(0xFF6ecdd4);
  final Color BabyRose = Color(0xFFf79c81);
  final Color BabyDarkGrey = Color(0xFF575757);
  final Color BabyTorquoise = Color(0xFF2e9fb4);

  List<Map<String, String>> premiumProducts = [];
  List<Map<String, String>> allProducts = [];

  @override
  void initState() {
    super.initState();
    premiumProducts = [
      {
        'title': 'Costway Foldable Baby\nStroller 2 in 1',
        'price': 'KES 23909',
        'description': 'Great quality',
      },
    ];

    allProducts = [
      {'title': 'Costway Foldable Baby\nStroller 2 in 1', 'price': 'KES 23909'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BabyBackgroundColor,
      body: Column(
        children: [
          // Header with logo
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Image.asset(
              'assets/png/Logo03.png',
              width: 100,
              height: 100,
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              enabled: true,
              decoration: InputDecoration(
                hintText: 'Search your product...',
                hintStyle: TextStyle(color: BabyDarkGrey),
                prefixIcon: Icon(Icons.search, color: BabyTeal),
                filled: true,
                fillColor: BabyBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: BabyTeal, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: BabyTeal, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: BabyTeal, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: BabyTeal, width: 1),
                ),
              ),
            ),
          ),

          // Category Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Baby Food'),
                  SizedBox(width: 10),
                  _buildCategoryChip('Clothing'),
                  SizedBox(width: 10),
                  _buildCategoryChip('Toys'),
                  SizedBox(width: 10),
                  _buildCategoryChip('Diapers'),
                  SizedBox(width: 10),
                  _buildCategoryChip('Toddler Beds'),
                ],
              ),
            ),
          ),

          // Premium Products Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 15,
                      bottom: 10,
                    ),
                    child: Text(
                      'Premium Products :',
                      style: TextStyle(
                        color: BabyDarkGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Premium Products Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (int i = 0; i < premiumProducts.length; i++) ...[
                          _buildProductCard(
                            premiumProducts[i]['title']!,
                            premiumProducts[i]['price']!,
                            premiumProducts[i]['description']!,
                          ),
                          if (i < premiumProducts.length - 1)
                            SizedBox(width: 15),
                        ],
                      ],
                    ),
                  ),

                  // All Products Section
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 25,
                      bottom: 0,
                    ),
                    child: Text(
                      'All Products :',
                      style: TextStyle(
                        color: BabyDarkGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // All Products Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: allProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductGridCard(
                          allProducts[index]['title']!,
                          allProducts[index]['price']!,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        color: BabyTorquoise,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Home',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Search',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Profile()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],  
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BabyTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getCategoryIcon(label), color: Colors.white, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Baby Food':
        return Icons.restaurant;
      case 'Clothing':
        return Icons.shopping_bag;
      case 'Toys':
        return Icons.toys;
      case 'Diapers':
        return Icons.baby_changing_station;
      case 'Toddler Beds':
        return Icons.bedroom_baby;
      default:
        return Icons.category;
    }
  }

  Widget _buildProductCard(String title, String price, String description) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BabyRose, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placeholder Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: BabyRose,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Icon(Icons.image, color: BabyRose, size: 40),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: BabyDarkGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  price,
                  style: TextStyle(
                    color: BabyRose,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: BabyDarkGrey, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'View More ❤',
                    style: TextStyle(
                      color: BabyRose,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(String title, String price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BabyRose, width: 2),
      ),
      child: Column(
        children: [
          // Placeholder Image
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: BabyRose,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Icon(Icons.image, color: BabyRose, size: 30),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: BabyDarkGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: BabyRose,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: BabyRose,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
