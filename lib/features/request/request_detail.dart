import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:postboy/features/request/widgets/response_panel.dart';
import '../../core/db/database_helper.dart';
import '../../core/models/api_request.dart';
import '../../core/models/api_response.dart';
import '../../core/services/http_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final ApiRequest request;
  final bool isPro;

  const RequestDetailScreen({super.key, required this.request,required this.isPro});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool loading = false;
  ApiResponse? response;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadBannerAd();

  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2109400871305297/4386638037', // Replace with test ID during development
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  Future<void> _executeRequest() async {
    setState(() {
      loading = true;
      response = null;
    });

    final res = await _httpService.send(widget.request);
   final success = res.statusCode >= 200 && res.statusCode < 300;
   await DatabaseHelper.instance.updateStatistics(success: success);

    setState(() {
      response = res;
      loading = false;
    });
  }

  Future<void> _deleteRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('requests', where: 'id = ?', whereArgs: [widget.request.id]);
      Navigator.pop(context, true); // Return to previous screen
    }
  }

  Widget _buildResponsePanel() {
    if (response == null) return const SizedBox();

    dynamic jsonData;

    if (response!.data is Map || response!.data is List) {
      jsonData = response!.data;
    } else {
      jsonData = null;
    }

    return ResponsePanel(
      body: jsonData,
      statusCode: response!.statusCode,
      headers: response?.headers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
     final isPro=widget.isPro;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRequest,
            tooltip: 'Delete Request',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Details
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Method', r.method.toUpperCase()),
                    _buildDetailRow('URL', r.url),
                    if (r.headers != null)
                      _buildDetailRow(
                        'Headers',
                        const JsonEncoder.withIndent('  ').convert(
                          r.headers != null ? json.decode(r.headers!) : {},
                        ),
                      ),
                    if (r.body != null) _buildDetailRow('Body', r.body!),
                  ],
                ),
              ),
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
            const SizedBox(height: 16),

            // Execute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: loading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(loading ? 'Sending...' : 'Execute Request'),
                onPressed: loading ? null : _executeRequest,
              ),
            ),

            const SizedBox(height: 16),

            // Response Panel
            _buildResponsePanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }
}
