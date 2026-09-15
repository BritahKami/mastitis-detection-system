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
