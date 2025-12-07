import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:postboy/features/request/request_detail.dart';
import '../../core/db/database_helper.dart';
import '../../core/models/api_request.dart';

class AllRequestsScreen extends StatefulWidget {
  final int? collectionId; // Only load requests for this collection if provided
  final String title;

  const AllRequestsScreen({super.key, this.collectionId, required this.title});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  List<ApiRequest> requests = [];
  List<ApiRequest> filteredRequests = [];
  bool loading = true;
  String searchQuery = "";

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;
  int _requestTapCount = 0;       // Counts request taps
  final int _interstitialFrequency = 3; // Show ad every 3 taps

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadRequests();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2109400871305297/8984358593', // Replace with test ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2109400871305297/2510872016', // Replace with test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void _maybeShowInterstitial(bool isPro) {
    if (isPro) return; // never show for pro users

    _requestTapCount++;
    if (_requestTapCount >= _interstitialFrequency && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // Preload next
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
      _requestTapCount = 0;
    }
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;

    String? where;
    List<Object?>? whereArgs;

    if (widget.collectionId != null) {
      where = 'collection_id = ?';
      whereArgs = [widget.collectionId!];
    }

    final result = await db.query(
      'requests',
      where: where,
      whereArgs: whereArgs,
      orderBy: "created_at DESC",
    );

    requests = result.map((e) => ApiRequest.fromJson(e)).toList();
    filteredRequests = requests;
    setState(() => loading = false);
  }

  void _filterRequests() {
    if (searchQuery.isEmpty) {
      filteredRequests = requests;
    } else {
      filteredRequests = requests.where((r) {
        final query = searchQuery.toLowerCase();
        return r.name.toLowerCase().contains(query) ||
            r.url.toLowerCase().contains(query) ||
            r.method.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _deleteRequest(ApiRequest r) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('requests', where: 'id = ?', whereArgs: [r.id]);

    requests.removeWhere((element) => element.id == r.id);
    _filterRequests();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isPro = args?['isPro'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(
              context,
              "/create-request",
              arguments: {"isPro": isPro},
            ),
          ),
          if (widget.collectionId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Popup for adding environment
              },
            )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search requests...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                searchQuery = val;
                _filterRequests();
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadRequests,
        child: filteredRequests.isEmpty
            ? _emptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRequests.length,
          itemBuilder: (_, i) => _requestTile(filteredRequests[i]),
        ),
      ),
      bottomNavigationBar: _isBannerAdReady && !isPro
          ? SizedBox(
        height: _bannerAd.size.height.toDouble(),
        width: _bannerAd.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd),
      )
          : null,
    );
  }

  Widget _requestTile(ApiRequest r) {
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Request?"),
            content: Text("Are you sure you want to delete '${r.name}'?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteRequest(r),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          onTap: () {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            final isPro = args?['isPro'] ?? false;

            _maybeShowInterstitial(isPro); // show ad if needed
            // Navigator.pushNamed(context, "/request-detail",
            //     arguments:[r,isPro]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailScreen(request: r, isPro: isPro),
              ),
            );

          },
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(.12),
            child: const Icon(Icons.http, color: Colors.blue),
          ),
          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.method.toUpperCase(), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                r.url,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteRequest(r),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No requests found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Create your first API request to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
