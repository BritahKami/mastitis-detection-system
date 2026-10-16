/// Domain models and mock data for Mastitis Detection System (MDS)
library;

enum StatusType {
  healthy,
  atRisk,
  pending,
}

class TestHistoryRecord {
  final String date;
  final bool mastitisPresent;

  const TestHistoryRecord({
    required this.date,
    required this.mastitisPresent,
  });

  String get label => mastitisPresent ? 'Mastitis present' : 'Mastitis absent';

  factory TestHistoryRecord.fromJson(Map<String, dynamic> json) {
    String dateStr = '';
    if (json['reading_time'] != null) {
      dateStr = json['reading_time'].toString().split('T').first;
    } else if (json['date'] != null) {
      dateStr = json['date'].toString();
    }
    final pred = json['prediction']?.toString().toLowerCase();
    final bool isPresent =
        json['mastitisPresent'] == true || pred == 'mastitis present';

    return TestHistoryRecord(
      date: dateStr,
      mastitisPresent: isPresent,
    );
  }
}

class Cow {
  final String id;
  final String tagNumber;
  final String breed;
  final int age;
  final StatusType status;
  final String lastTested;
  final List<TestHistoryRecord> history;

  const Cow({
    required this.id,
    required this.tagNumber,
    required this.breed,
    required this.age,
    required this.status,
    required this.lastTested,
    this.history = const [],
  });

  String get displayTag => tagNumber.startsWith('Tag ') ? tagNumber : 'Tag $tagNumber';
  String get rawTagId => tagNumber.replaceAll('Tag ', '').trim();

  factory Cow.fromJson(Map<String, dynamic> json) {
    StatusType parseStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'at risk':
        case 'atrisk':
          return StatusType.atRisk;
        case 'pending':
          return StatusType.pending;
        case 'healthy':
        default:
          return StatusType.healthy;
      }
    }

    final dynamic historyData = json['history'];
    List<TestHistoryRecord> historyList = [];
    if (historyData is List) {
      historyList = historyData
          .map((h) => TestHistoryRecord.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    final rawTag = json['cow_tag'] ?? json['tagNumber'] ?? '';
    final idVal = json['cow_id']?.toString() ?? json['id']?.toString() ?? '';

    return Cow(
      id: idVal,
      tagNumber: rawTag.toString(),
      breed: json['breed']?.toString() ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : (int.tryParse(json['age']?.toString() ?? '') ?? 0),
      status: parseStatus(
          json['health_status']?.toString() ?? json['status']?.toString()),
      lastTested: json['lastTested']?.toString() ??
          (historyList.isNotEmpty ? historyList.first.date : 'Not tested'),
      history: historyList,
    );
  }

  Cow copyWith({
    String? id,
    String? tagNumber,
    String? breed,
    int? age,
    StatusType? status,
    String? lastTested,
    List<TestHistoryRecord>? history,
  }) {
    return Cow(
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      status: status ?? this.status,
      lastTested: lastTested ?? this.lastTested,
      history: history ?? this.history,
    );
  }
}

class DetectionResult {
  final String tagNumber;
  final String timestamp;
  final double temperature;
  final double pH;
  final double conductivity;
  final StatusType status;
  final String predictionLabel;

  const DetectionResult({
    required this.tagNumber,
    required this.timestamp,
    required this.temperature,
    required this.pH,
    required this.conductivity,
    required this.status,
    required this.predictionLabel,
  });

  static DetectionResult sampleForCow(String tagNumber) {
    return DetectionResult(
      tagNumber: tagNumber,
      timestamp: '2026-09-09 10:30',
      temperature: 39.4,
      pH: 6.85,
      conductivity: 6.42,
      status: StatusType.atRisk,
      predictionLabel: 'Mastitis present',
    );
  }

  static DetectionResult healthySampleForCow(String tagNumber) {
    return DetectionResult(
      tagNumber: tagNumber,
      timestamp: '2026-09-09 10:30',
      temperature: 38.6,
      pH: 6.55,
      conductivity: 5.12,
      status: StatusType.healthy,
      predictionLabel: 'Mastitis absent',
    );
  }
}

class AlertNotification {
  final String id;
  final String tagNumber;
  final String timestamp;
  final bool isUnread;

  const AlertNotification({
    required this.id,
    required this.tagNumber,
    required this.timestamp,
    required this.isUnread,
  });

  StatusType get badgeState => isUnread ? StatusType.atRisk : StatusType.healthy;
  String get badgeLabel => isUnread ? 'Unread' : 'Read';

  AlertNotification copyWith({
    String? id,
    String? tagNumber,
    String? timestamp,
    bool? isUnread,
  }) {
    return AlertNotification(
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      timestamp: timestamp ?? this.timestamp,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase();
    final isUnread = statusStr == 'unread' || json['isUnread'] == true;
    final tag = json['cow_tag'] ?? json['tagNumber'] ?? 'Unknown Cow';
    final time = json['send_time'] ?? json['timestamp'] ?? '';

    return AlertNotification(
      id: json['alert_id']?.toString() ?? json['id']?.toString() ?? '',
      tagNumber: tag.toString(),
      timestamp: time.toString().contains('T')
          ? time.toString().split('T').last.substring(0, 5)
          : time.toString(),
      isUnread: isUnread,
    );
  }
}

class FarmerProfile {
  final int farmerId;
  final String firstName;
  final String lastName;
  final String email;
  final int totalCows;

  const FarmerProfile({
    required this.farmerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.totalCows,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      farmerId: json['farmer_id'] is int
          ? json['farmer_id'] as int
          : (int.tryParse(json['farmer_id']?.toString() ?? '') ?? 0),
      firstName: json['fname']?.toString() ?? '',
      lastName: json['lname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      totalCows: json['total_cows'] is int
          ? json['total_cows'] as int
          : (int.tryParse(json['total_cows']?.toString() ?? '') ?? 0),
    );
  }
}

class MDSMockRepository {
  static List<Cow> getInitialCows() {
    return [
      const Cow(
        id: '1',
        tagNumber: 'Tag 101',
        breed: 'Holstein Friesian',
        age: 4,
        status: StatusType.healthy,
        lastTested: '09/01',
        history: [
          TestHistoryRecord(date: '2026-09-01', mastitisPresent: false),
          TestHistoryRecord(date: '2026-08-15', mastitisPresent: false),
          TestHistoryRecord(date: '2026-08-01', mastitisPresent: false),
        ],
      ),
      const Cow(
        id: '2',
        tagNumber: 'Tag 102',
        breed: 'Jersey',
        age: 3,
        status: StatusType.atRisk,
        lastTested: '09/02',
        history: [
          TestHistoryRecord(date: '2026-09-02', mastitisPresent: true),
          TestHistoryRecord(date: '2026-08-20', mastitisPresent: false),
          TestHistoryRecord(date: '2026-08-05', mastitisPresent: true),
        ],
      ),
      const Cow(
        id: '3',
        tagNumber: 'Tag 103',
        breed: 'Ayrshire',
        age: 5,
        status: StatusType.pending,
        lastTested: '09/03',
        history: [
          TestHistoryRecord(date: '2026-09-03', mastitisPresent: false),
          TestHistoryRecord(date: '2026-08-18', mastitisPresent: false),
        ],
      ),
      const Cow(
        id: '4',
        tagNumber: 'Tag 104',
        breed: 'Guernsey',
        age: 2,
        status: StatusType.healthy,
        lastTested: '09/04',
        history: [
          TestHistoryRecord(date: '2026-09-04', mastitisPresent: false),
          TestHistoryRecord(date: '2026-08-22', mastitisPresent: false),
        ],
      ),
      const Cow(
        id: '5',
        tagNumber: 'Tag 105',
        breed: 'Brown Swiss',
        age: 4,
        status: StatusType.atRisk,
        lastTested: '09/05',
        history: [
          TestHistoryRecord(date: '2026-09-05', mastitisPresent: true),
          TestHistoryRecord(date: '2026-08-25', mastitisPresent: false),
        ],
      ),
    ];
  }

  static List<AlertNotification> getInitialAlerts() {
    return [
      const AlertNotification(
        id: 'a1',
        tagNumber: 'Tag 102',
        timestamp: '09/08 14:30',
        isUnread: true,
      ),
      const AlertNotification(
        id: 'a2',
        tagNumber: 'Tag 105',
        timestamp: '09/07 10:15',
        isUnread: true,
      ),
      const AlertNotification(
        id: 'a3',
        tagNumber: 'Tag 101',
        timestamp: '09/05 08:45',
        isUnread: false,
      ),
      const AlertNotification(
        id: 'a4',
        tagNumber: 'Tag 104',
        timestamp: '09/04 16:20',
        isUnread: false,
      ),
      const AlertNotification(
        id: 'a5',
        tagNumber: 'Tag 103',
        timestamp: '09/03 11:00',
        isUnread: false,
      ),
    ];
  }
}
