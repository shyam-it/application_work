class SiteWorkTime {
  final String siteId;
  final String siteName;
  final String startTime;
  final String endTime;

  const SiteWorkTime({
    required this.siteId,
    required this.siteName,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory SiteWorkTime.fromMap(Map<String, dynamic> map) {
    return SiteWorkTime(
      siteId: map['siteId'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
    );
  }
}

class AttendanceRecord {
  final String workerId;
  final String date;
  final String status;
  final List<SiteWorkTime> siteWorkTimes;

  const AttendanceRecord({
    required this.workerId,
    required this.date,
    required this.status,
    this.siteWorkTimes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'date': date,
      'status': status,
      'siteWorkTimes': siteWorkTimes.map((item) => item.toMap()).toList(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final rawTimes = map['siteWorkTimes'] as List<dynamic>? ?? [];

    return AttendanceRecord(
      workerId: map['workerId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      status: map['status'] as String? ?? 'Not marked',
      siteWorkTimes: rawTimes
          .whereType<Map<String, dynamic>>()
          .map(SiteWorkTime.fromMap)
          .toList(),
    );
  }
}
