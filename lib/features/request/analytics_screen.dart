import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/db/database_helper.dart';
import '../../core/models/api_request.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<ApiRequest> requests = [];
  bool loading = true;

  // Statistics counters
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;

    // Load requests and collections
    final requestResult = await db.query('requests', orderBy: "created_at DESC");

    // Load statistics from statistics table
    final statsResult = await db.query('request_statistics', limit: 1);
    if (statsResult.isNotEmpty) {
      final stats = statsResult.first;
      successfulRequests = stats['successful'] as int? ?? 0;
      failedRequests = stats['failed'] as int? ?? 0;
    }

    setState(() {
      requests = requestResult.map((e) => ApiRequest.fromJson(e)).toList();
      totalRequests = requests.length as int? ?? 0;
      loading = false;
    });
  }

  Map<String, int> _countByMethod() {
    final map = <String, int>{};
    for (var r in requests) {
      map[r.method.toUpperCase()] = (map[r.method.toUpperCase()] ?? 0) + 1;
    }
    return map;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 20),
            _buildChartCard("Requests by Method", _countByMethod()),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOverviewItem("Successful", successfulRequests, Colors.green),
            _buildOverviewItem("Failed", failedRequests, Colors.red),
          ],

        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, int count, Color color) {
    return Column(
      children: [
        Text("$count",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildChartCard(String title, Map<String, int> data) {
    final items = data.entries.toList();
    if (items.isEmpty) return const SizedBox();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sections: items
                    .map(
                      (e) => PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.key} (${e.value})',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
                    .toList(),
              )),
            ),
          ],
        ),
      ),
    );
  }

}
