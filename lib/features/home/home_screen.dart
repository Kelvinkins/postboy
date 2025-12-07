import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:postboy/features/request/analytics_screen.dart';
import '../../core/db/database_helper.dart';
import '../../core/models/api_request.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalRequests = 0;
  String lastRequestName = "--";
  String topMethod = "--";
  bool isPro = false;
  bool loadingPro = true;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;


  Future<void> _loadProStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isPro = false;
        loadingPro = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('app_config')
        .get();

    if (doc.exists) {
      isPro = doc.data()?['isPremium'] ?? false;
    } else {
      isPro = false;
    }

    setState(() {
      loadingPro = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadBannerAd();
    // _loadProStatus();
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query("requests", orderBy: "id DESC");

    if (rows.isEmpty) {
      setState(() {
        totalRequests = 0;
        lastRequestName = "--";
        topMethod = "--";
      });
      return;
    }

    final List<ApiRequest> requests = rows.map((e) => ApiRequest.fromJson(e)).toList();

    totalRequests = requests.length;
    lastRequestName = requests.first.name;

    final methodCount = <String, int>{};
    for (var r in requests) {
      methodCount[r.method] = (methodCount[r.method] ?? 0) + 1;
    }

    topMethod = methodCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    setState(() {});
  }

  void _loadBannerAd() {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-2109400871305297/9114552238',
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      )
        ..load();

  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Widget _actionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Postboy Home"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/settings"),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, "/create-request",
          arguments: {"isPro": isPro},
        ),
        label: const Text("New Request"),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome Back!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Here’s a quick overview of your API activity:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Total Requests", "$totalRequests", Icons.list_alt, Colors.blue),
                      _buildStatCard("Recent Request", lastRequestName, Icons.history, Colors.green),
                      _buildStatCard("Top Method", topMethod, Icons.flash_on, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isBannerAdReady && !isPro)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.white,
                        width: _bannerAd.size.width.toDouble(),
                        height: _bannerAd.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd),
                      ),
                    ),

                  const SizedBox(height: 30),
                  const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _actionTile(title: "My Requests", icon: Icons.list, color: Colors.teal, onTap: () => Navigator.pushNamed(context, "/requests",
                        arguments: {"isPro": isPro},
                      )),
                      // _actionTile(title: "Environments", icon: Icons.collections, color: Colors.teal, onTap: () => Navigator.pushNamed(context, "/environments",
                      //   arguments: {"isPro": isPro},
                      // )),

                      SizedBox(height: 500, child: AnalyticsScreen()),
                    ],
                  ),
                  const SizedBox(height: 100), // space for ad
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 10),
              Text(value, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }



}
