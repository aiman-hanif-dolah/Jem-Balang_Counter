import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BeverageSalesTrackerApp());
}

class BeverageSalesTrackerApp extends StatelessWidget {
  const BeverageSalesTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beverage Sales Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: Colors.deepOrange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.amber,
          surface: Color(0xFF131B2E),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme.apply(
            bodyColor: const Color(0xFFE2E8F0),
            displayColor: Colors.white,
          ),
        ),
      ),
      home: const BeverageSalesPage(),
    );
  }
}

class Beverage {
  final String name;
  final String size;
  final int price;
  int quantity;
  final String imageUrl;

  Beverage({
    required this.name,
    required this.size,
    required this.price,
    this.quantity = 0,
    required this.imageUrl,
  });

  int get total => price * quantity;

  List<Color> get gradientColors {
    if (name.contains('Thai Tea')) {
      return [const Color(0xFFF36A22), const Color(0xFFF9A825)]; // Orange-Amber
    } else if (name.contains('Green Tea')) {
      return [const Color(0xFF00C853), const Color(0xFFB9F6CA)]; // Emerald Mint
    } else if (name.contains('Soda Herbs')) {
      return [const Color(0xFF00B0FF), const Color(0xFF00E5FF)]; // Cyan
    } else {
      return [const Color(0xFFEC407A), const Color(0xFFAB47BC)]; // Ribena Soda Magenta-Purple
    }
  }

  Color get primaryColor => gradientColors[0];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color border;
  final Color background;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 20.0,
    this.border = const Color(0x1AFFFFFF),
    this.background = const Color(0x0DFFFFFF),
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: border,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class BeverageSalesPage extends StatefulWidget {
  const BeverageSalesPage({super.key});

  @override
  State<BeverageSalesPage> createState() => _BeverageSalesPageState();
}

class _BeverageSalesPageState extends State<BeverageSalesPage> {
  FirebaseFirestore? _firestore;

  List<Beverage> beverages = [
    Beverage(
      name: 'Thai Tea',
      size: 'Small',
      price: 4,
      imageUrl: 'assets/images/thai_tea_small.png',
    ),
    Beverage(
      name: 'Green Tea',
      size: 'Small',
      price: 4,
      imageUrl: 'assets/images/green_tea_small.png',
    ),
    Beverage(
      name: 'Soda Herbs',
      size: 'Small',
      price: 3,
      imageUrl: 'assets/images/soda_herbs_small.png',
    ),
    Beverage(
      name: 'Ribena Soda',
      size: 'Small',
      price: 3,
      imageUrl: 'assets/images/ribena_soda_small.png',
    ),
    Beverage(
      name: 'Thai Tea',
      size: 'Big',
      price: 5,
      imageUrl: 'assets/images/thai_tea_big.png',
    ),
    Beverage(
      name: 'Green Tea',
      size: 'Big',
      price: 5,
      imageUrl: 'assets/images/green_tea_big.png',
    ),
    Beverage(
      name: 'Soda Herbs',
      size: 'Big',
      price: 5,
      imageUrl: 'assets/images/soda_herbs_big.png',
    ),
    Beverage(
      name: 'Ribena Soda',
      size: 'Big',
      price: 5,
      imageUrl: 'assets/images/ribena_soda_big.png',
    ),
  ];

  int totalSales = 0;

  int get totalDrinksSold => beverages.fold(0, (acc, item) => acc + item.quantity);

  @override
  void initState() {
    super.initState();
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized (offline/testing mode): $e');
    }
    _loadInitialData();
  }

  void _loadInitialData() async {
    if (_firestore == null) {
      setState(() {
        totalSales = beverages.fold(0, (acc, item) => acc + item.total);
      });
      return;
    }
    try {
      final snapshot = await _firestore!.collection('beverages').get();

      if (snapshot.docs.isEmpty) {
        for (var beverage in beverages) {
          await _firestore!
              .collection('beverages')
              .doc('${beverage.name}_${beverage.size}')
              .set(beverage.toMap());
        }
        _updateTotalSalesFirestore();
      } else {
        setState(() {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            Beverage? beverage = beverages.firstWhereOrNull(
                  (bev) => bev.name == data['name'] && bev.size == data['size'],
            );
            if (beverage != null) {
              beverage.quantity = data['quantity'] ?? 0;
            } else {
              debugPrint(
                  'No matching beverage found for ${data['name']} (${data['size']})');
            }
          }
          totalSales = beverages.fold(0, (acc, item) => acc + item.total);
        });
      }

      _firestore!.collection('beverages').snapshots().listen((snapshot) {
        setState(() {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            Beverage? beverage = beverages.firstWhereOrNull(
                  (bev) => bev.name == data['name'] && bev.size == data['size'],
            );
            if (beverage != null) {
              beverage.quantity = data['quantity'] ?? 0;
            } else {
              debugPrint(
                  'No matching beverage found for ${data['name']} (${data['size']})');
            }
          }
          totalSales = beverages.fold(0, (acc, item) => acc + item.total);
        });
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _updateTotalSalesFirestore() async {
    if (_firestore == null) return;
    try {
      await _firestore!
          .collection('sales')
          .doc('total_sales')
          .set({'total': totalSales}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating total sales: $e');
    }
  }

  void _updateQuantity(Beverage beverage, int change) async {
    setState(() {
      beverage.quantity += change;
      if (beverage.quantity < 0) beverage.quantity = 0;
      totalSales = beverages.fold(0, (acc, item) => acc + item.total);
    });

    if (_firestore == null) return;
    try {
      await _firestore!
          .collection('beverages')
          .doc('${beverage.name}_${beverage.size}')
          .update({
        'quantity': beverage.quantity,
      });
      _updateTotalSalesFirestore();
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  Widget _buildModernHeader(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 480;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 48,
                  width: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "JEM-BALANG",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Sales Dashboard",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  "BIC31802",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatsBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        background: const Color(0x14FFFFFF),
        border: const Color(0x1FFFFFFF),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.deepOrange.withValues(alpha: 0.4),
                      Colors.deepOrange.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.amber.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL SALES",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "RM ${totalSales.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.deepOrangeAccent,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 45,
                  width: 1.5,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL DRINKS SOLD",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$totalDrinksSold Cups",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeverageItem(Beverage beverage, BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final activeColor = beverage.primaryColor;
    final isBig = beverage.size.toLowerCase() == 'big';
    final bool isSmallScreen = screenWidth < 360;

    return GlassCard(
      margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      background: const Color(0x0AFFFFFF),
      border: const Color(0x12FFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: isSmallScreen ? 64 : 90,
                  height: isSmallScreen ? 64 : 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.25),
                        blurRadius: isSmallScreen ? 15 : 25,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  beverage.imageUrl,
                  height: isSmallScreen ? 65 : 95,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isBig ? Colors.purple : Colors.teal).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: (isBig ? Colors.purpleAccent : Colors.tealAccent).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      beverage.size.toUpperCase(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 8,
                        fontWeight: FontWeight.w900,
                        color: isBig ? Colors.purpleAccent : Colors.tealAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            beverage.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'RM ${beverage.price.toStringAsFixed(2)} each',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          Container(
            height: isSmallScreen ? 32 : 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: beverage.quantity > 0
                        ? () => _updateQuantity(beverage, -1)
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.remove_rounded,
                        size: isSmallScreen ? 14 : 18,
                        color: beverage.quantity > 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '${beverage.quantity}',
                      key: ValueKey<int>(beverage.quantity),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w900,
                        color: beverage.quantity > 0 ? activeColor : Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateQuantity(beverage, 1),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: isSmallScreen ? 24 : 28,
                        height: isSmallScreen ? 24 : 28,
                        decoration: BoxDecoration(
                          color: beverage.quantity > 0 ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: isSmallScreen ? 14 : 18,
                          color: beverage.quantity > 0 ? activeColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          SizedBox(
            height: isSmallScreen ? 14 : 16,
            child: AnimatedOpacity(
              opacity: beverage.quantity > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Total: RM ${beverage.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Dynamically calculate grid columns and cell aspect ratio based on width
    int crossAxisCount = 2;
    double aspectRatio = 0.72;

    if (screenWidth >= 1200) {
      crossAxisCount = 4;
      aspectRatio = 0.75;
    } else if (screenWidth >= 900) {
      crossAxisCount = 3;
      aspectRatio = 0.74;
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
      aspectRatio = 0.73;
    } else if (screenWidth >= 380) {
      crossAxisCount = 2;
      aspectRatio = 0.70;
    } else {
      crossAxisCount = 2;
      aspectRatio = 0.62;
    }

    // On very short viewports (e.g. mobile landscape height < 600),
    // allow the entire page to scroll together rather than locking the header.
    final bool useSingleScroll = screenHeight < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06090F),
              Color(0xFF111724),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: useSingleScroll
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildModernHeader(context),
                          _buildHeroStatsBoard(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 10, bottom: 20),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: beverages.length,
                              itemBuilder: (context, index) {
                                return _buildBeverageItem(beverages[index], context);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildModernHeader(context),
                        _buildHeroStatsBoard(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(top: 10, bottom: 20),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: beverages.length,
                              itemBuilder: (context, index) {
                                return _buildBeverageItem(beverages[index], context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  FirebaseFirestore? _firestore;

  int _question1Rating = 2;
  int _question2Rating = 2;
  int _question3Rating = 2;

  @override
  void initState() {
    super.initState();
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized (offline/testing mode): $e');
    }
  }

  void _submitFeedback() async {
    if (_firestore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully (Offline mode)'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      Navigator.pop(context);
      return;
    }
    try {
      await _firestore!.collection('feedbacks').add({
        'question1': _question1Rating,
        'question2': _question2Rating,
        'question3': _question3Rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting feedback'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildFeedbackHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GIVE FEEDBACK",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              Text(
                "Tell us about your experience",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiRating(
      String question, int rating, ValueChanged<int> onChanged) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    List<String> emojis = ['😞', '😐', '😃'];
    List<Color> colors = [Colors.redAccent, Colors.amberAccent, Colors.greenAccent];
    List<String> labels = ['Unsatisfied', 'Neutral', 'Delighted'];

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      background: const Color(0x0DFFFFFF),
      border: const Color(0x14FFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(emojis.length, (index) {
              int emojiRating = index + 1;
              final isSelected = rating == emojiRating;
              final activeColor = colors[index];
              return GestureDetector(
                onTap: () => onChanged(emojiRating),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          emojis[index],
                          style: TextStyle(fontSize: isSmallScreen ? 30 : 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06090F),
              Color(0xFF111724),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  children: [
                    _buildFeedbackHeader(context),
                    _buildEmojiRating(
                      'How would you rate our service?',
                      _question1Rating,
                      (value) {
                        setState(() {
                          _question1Rating = value;
                        });
                      },
                    ),
                    _buildEmojiRating(
                      'How would you rate the taste?',
                      _question2Rating,
                      (value) {
                        setState(() {
                          _question2Rating = value;
                        });
                      },
                    ),
                    _buildEmojiRating(
                      'How likely are you to recommend us?',
                      _question3Rating,
                      (value) {
                        setState(() {
                          _question3Rating = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _submitFeedback,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.deepOrange,
                              Colors.orangeAccent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
