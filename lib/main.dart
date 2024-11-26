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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          elevation: 0,
        ),
        textTheme: GoogleFonts.fredokaTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange)
            .copyWith(secondary: Colors.amber),
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

class BeverageSalesPage extends StatefulWidget {
  const BeverageSalesPage({super.key});

  @override
  State<BeverageSalesPage> createState() => _BeverageSalesPageState();
}

class _BeverageSalesPageState extends State<BeverageSalesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final snapshot = await _firestore.collection('beverages').get();

      if (snapshot.docs.isEmpty) {
        for (var beverage in beverages) {
          await _firestore
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
              print(
                  'No matching beverage found for ${data['name']} (${data['size']})');
            }
          }
          totalSales = beverages.fold(0, (sum, item) => sum + item.total);
        });
      }

      _firestore.collection('beverages').snapshots().listen((snapshot) {
        setState(() {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            Beverage? beverage = beverages.firstWhereOrNull(
                  (bev) => bev.name == data['name'] && bev.size == data['size'],
            );
            if (beverage != null) {
              beverage.quantity = data['quantity'] ?? 0;
            } else {
              print(
                  'No matching beverage found for ${data['name']} (${data['size']})');
            }
          }
          totalSales = beverages.fold(0, (sum, item) => sum + item.total);
        });
      });
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _updateTotalSalesFirestore() async {
    try {
      await _firestore
          .collection('sales')
          .doc('total_sales')
          .set({'total': totalSales}, SetOptions(merge: true));
    } catch (e) {
      print('Error updating total sales: $e');
    }
  }

  void _updateQuantity(Beverage beverage, int change) async {
    setState(() {
      beverage.quantity += change;
      if (beverage.quantity < 0) beverage.quantity = 0;
      totalSales = beverages.fold(0, (sum, item) => sum + item.total);
    });

    try {
      await _firestore
          .collection('beverages')
          .doc('${beverage.name}_${beverage.size}')
          .update({
        'quantity': beverage.quantity,
      });
      _updateTotalSalesFirestore();
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Widget _buildBeverageItem(Beverage beverage) {
    return Card(
      color: Colors.amber.shade50,
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            beverage.imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          Text(
            '${beverage.name} (${beverage.size})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'RM${beverage.price} each',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: beverage.quantity > 0
                    ? () => _updateQuantity(beverage, -1)
                    : null,
                icon: const Icon(Icons.remove_circle, size: 24),
                color: Colors.deepOrange,
              ),
              Text(
                '${beverage.quantity}',
                style: const TextStyle(fontSize: 18),
              ),
              IconButton(
                onPressed: () => _updateQuantity(beverage, 1),
                icon: const Icon(Icons.add_circle, size: 24),
                color: Colors.deepOrange,
              ),
            ],
          ),
          Text(
            'Total: RM${beverage.total}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSales() {
    return Container(
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Total Sales: RM$totalSales',
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Image.asset(
        'assets/images/logo.png',
        height: 80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Text(
            "Jem-Balang Sales Tracker",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              children: beverages
                  .map((beverage) => _buildBeverageItem(beverage))
                  .toList(),
            ),
          ),
          _buildTotalSales(),
        ],
      ),
    );
  }
}

// New FeedbackPage class added below
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _question1Rating = 2;
  int _question2Rating = 2;
  int _question3Rating = 2;

  void _submitFeedback() async {
    try {
      await _firestore.collection('feedbacks').add({
        'question1': _question1Rating,
        'question2': _question2Rating,
        'question3': _question3Rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting feedback')),
      );
    }
  }

  Widget _buildEmojiRating(
      String question, int rating, ValueChanged<int> onChanged) {
    List<String> emojis = ['😞', '😐', '😃'];
    List<Color> colors = [Colors.red, Colors.amber, Colors.green];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(emojis.length, (index) {
            int emojiRating = index + 1;
            return GestureDetector(
              onTap: () => onChanged(emojiRating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: rating == emojiRating
                      ? colors[index].withOpacity(0.2)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rating == emojiRating
                        ? colors[index]
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Text(
                  emojis[index],
                  style: TextStyle(fontSize: 40),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'We value your feedback!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Submit Feedback', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
