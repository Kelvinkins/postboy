class RequestStatistics {
  final int? id;            // Primary key (optional)
  final int totalRequests;   // Total requests sent
  final int successful;      // Number of successful requests
  final int failed;          // Number of failed requests
  final String? lastUpdated; // Timestamp of last update

  RequestStatistics({
    this.id,
    this.totalRequests = 0,
    this.successful = 0,
    this.failed = 0,
    this.lastUpdated,
  });

  RequestStatistics copyWith({
    int? totalRequests,
    int? successful,
    int? failed,
    String? lastUpdated,
  }) {
    return RequestStatistics(
      id: id,
      totalRequests: totalRequests ?? this.totalRequests,
      successful: successful ?? this.successful,
      failed: failed ?? this.failed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'total_requests': totalRequests,
    'successful': successful,
    'failed': failed,
    'last_updated': lastUpdated ?? DateTime.now().toIso8601String(),
  };

  factory RequestStatistics.fromJson(Map<String, dynamic> json) =>
      RequestStatistics(
        id: json['id'],
        totalRequests: json['total_requests'] ?? 0,
        successful: json['successful'] ?? 0,
        failed: json['failed'] ?? 0,
        lastUpdated: json['last_updated'],
      );
}
