import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;
  bool _loading = true;

  final String _productId = 'postboy_pro'; // Your subscription ID
  List<ProductDetails> _products = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase stream error: $error")),
        );
      },
    );

    _initialize();
  }

  Future<void> _initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      setState(() => _loading = false);
      return;
    }

    final response = await _iap.queryProductDetails({_productId});

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching product: ${response.error!.message}")),
      );
    }

    if (response.notFoundIDs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product not found.")),
      );
    }

    setState(() {
      _products = response.productDetails;
      _loading = false;
    });
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyPurchase(purchase);
        setState(() {

        });
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Mark user as premium in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('app_config')
          .set({
        'isPremium': true,
        'purchaseId': purchase.purchaseID,
        'premiumExpiry': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      }, SetOptions(merge: true));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🎉 Purchase successful! Postboy Pro activated.")),
    );

    Navigator.pop(context);
  }
  Future<void> _buySubscription() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product not available.")),
      );
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: _products.first);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam); // works for subscriptions too
  }


  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Restoring purchases...")),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upgrade to Postboy Pro")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Icon(Icons.workspace_premium, color: Colors.amber, size: 80),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Postboy Pro",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Unlock all premium features:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _feature(Icons.block_flipped, "Remove Ads"),
            _feature(Icons.lock_open, "Unlock unlimited Requests"),
            _feature(Icons.save, "Organize requests in collections"),
            _feature(Icons.pie_chart, "Analytics"),
            const SizedBox(height: 40),
            _pricingCard(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _buySubscription,
                child: Text(
                  _products.isNotEmpty
                      ? "Upgrade Now (${_products.first.price})/Month"
                      : "Upgrade Now",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _restorePurchases,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  "Restore Purchase",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Cancel anytime. No hidden fees.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _pricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pricing",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Google Play / App Store will determine the price based on your country and currency.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          Text(
            "The exact amount will be shown during the checkout pop-up.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
