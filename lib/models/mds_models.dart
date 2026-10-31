/// Domain models and mock data for Mastitis Detection System (MDS)
library;

enum StatusType {
  healthy,
  atRisk,
  pending,
}

class TestHistoryRecord {
  final int? resultId;
  final int? readingId;
  final String date;
  final String formattedTime;
  final bool mastitisPresent;
  final double temperature;
  final double pH;
  final double electricalConductivity;
  final String diagnosticOutcome;

  const TestHistoryRecord({
    this.resultId,
    this.readingId,
    required this.date,
    this.formattedTime = '',
    required this.mastitisPresent,
    this.temperature = 0.0,
    this.pH = 0.0,
    this.electricalConductivity = 0.0,
    this.diagnosticOutcome = '',
  });

  String get label => mastitisPresent ? 'Mastitis present' : 'Mastitis absent';

  factory TestHistoryRecord.fromJson(Map<String, dynamic> json) {
    String rawTime = json['reading_time']?.toString() ??
        json['detection_time']?.toString() ??
        json['timestamp']?.toString() ??
        json['date']?.toString() ??
        '';

    String dateStr = '';
    String timeStr = '';
    if (rawTime.isNotEmpty) {
      final parsed = DateTime.tryParse(rawTime);
      if (parsed != null) {
        final local = parsed.toLocal();
        final year = local.year.toString().padLeft(4, '0');
        final month = local.month.toString().padLeft(2, '0');
        final day = local.day.toString().padLeft(2, '0');
        final hour = local.hour.toString().padLeft(2, '0');
        final minute = local.minute.toString().padLeft(2, '0');
        dateStr = '$year-$month-$day';
        timeStr = '$hour:$minute';
      } else {
        dateStr = rawTime.split('T').first;
      }
    }

    final rawPred = json['prediction']?.toString() ??
        json['diagnostic_status']?.toString() ??
        json['diagnosticOutcome']?.toString() ??
        '';
    final predLower = rawPred.toLowerCase();
    final bool isPresent = json['mastitisPresent'] == true ||
        predLower.contains('present') ||
        predLower == 'at risk';

    final num? tempNum = json['temperature'] as num?;
    final num? phNum = (json['pH'] ?? json['ph']) as num?;
    final num? condNum = (json['electrical_conductivity'] ??
        json['electricalConductivity'] ??
        json['conductivity']) as num?;

    final resId = json['result_id'] is int
        ? json['result_id'] as int
        : int.tryParse(json['result_id']?.toString() ?? json['resultId']?.toString() ?? '');
    final readId = json['reading_id'] is int
        ? json['reading_id'] as int
        : int.tryParse(json['reading_id']?.toString() ?? json['readingId']?.toString() ?? '');

    return TestHistoryRecord(
      resultId: resId,
      readingId: readId,
      date: dateStr,
      formattedTime: timeStr,
      mastitisPresent: isPresent,
      temperature: tempNum?.toDouble() ?? 0.0,
      pH: phNum?.toDouble() ?? 0.0,
      electricalConductivity: condNum?.toDouble() ?? 0.0,
      diagnosticOutcome: rawPred.isNotEmpty
          ? rawPred
          : (isPresent ? 'Mastitis Present' : 'Mastitis Absent'),
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

  String get displayTag => tagNumber;
  String get rawTagId =>
      tagNumber.startsWith('Tag ') ? tagNumber.substring(4).trim() : tagNumber;

  factory Cow.fromJson(Map<String, dynamic> json) {
    StatusType parseStatus(String? status) {
      switch (status?.toLowerCase().trim()) {
        case 'at risk':
        case 'atrisk':
        case 'mastitis present':
          return StatusType.atRisk;
        case 'healthy':
        case 'mastitis absent':
          return StatusType.healthy;
        case 'pending':
        default:
          return StatusType.pending; // Default untested cows to Pending
      }
    }

    final Map<String, dynamic> source =
        json['cow'] is Map<String, dynamic> ? json['cow'] as Map<String, dynamic> : json;

    final dynamic historyData = source['history'];
    List<TestHistoryRecord> historyList = [];
    if (historyData is List) {
      historyList = historyData
          .map((h) => TestHistoryRecord.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    final rawTag =
        source['cow_tag'] ?? source['tag_number'] ?? source['tagNumber'] ?? '';
    final idVal = source['cow_id']?.toString() ?? source['id']?.toString() ?? '';

    // Parse last_tested timestamp and convert to local device time
    String lastTestedStr = 'Not tested';
    final rawLastTested = source['last_tested'] ??
        source['lastTested'] ??
        (historyList.isNotEmpty ? '${historyList.first.date} ${historyList.first.formattedTime}'.trim() : null);

    if (rawLastTested != null && rawLastTested.toString().isNotEmpty && rawLastTested.toString() != 'Not tested') {
      final parsed = DateTime.tryParse(rawLastTested.toString());
      if (parsed != null) {
        final local = parsed.toLocal();
        final year = local.year.toString().padLeft(4, '0');
        final month = local.month.toString().padLeft(2, '0');
        final day = local.day.toString().padLeft(2, '0');
        final hour = local.hour.toString().padLeft(2, '0');
        final minute = local.minute.toString().padLeft(2, '0');
        lastTestedStr = '$year-$month-$day $hour:$minute';
      } else {
        lastTestedStr = rawLastTested.toString();
      }
    }

    return Cow(
      id: idVal,
      tagNumber: rawTag.toString(),
      breed: source['breed']?.toString() ?? '',
      age: source['age'] is int
          ? source['age'] as int
          : (int.tryParse(source['age']?.toString() ?? '') ?? 0),
      status: parseStatus(
          source['health_status']?.toString() ?? source['status']?.toString()),
      lastTested: lastTestedStr,
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

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    // Unpack nested 'result' dictionary if present (from backend DetectionResultResponse)
    final Map<String, dynamic> source =
        json['result'] is Map<String, dynamic> ? json['result'] as Map<String, dynamic> : json;

    final String prediction = source['prediction']?.toString() ??
        json['prediction']?.toString() ??
        source['diagnostic_status']?.toString() ??
        json['diagnostic_status']?.toString() ??
        source['diagnosis']?.toString() ??
        json['diagnosis']?.toString() ??
        'Mastitis Absent';

    final String healthStatus = json['health_status']?.toString() ??
        source['health_status']?.toString() ??
        json['diagnostic_status']?.toString() ??
        '';

    final bool isMastitisPresent = prediction.toLowerCase().contains('present') ||
        healthStatus.toLowerCase() == 'at risk';

    final num? rawTemp = source['temperature'] as num? ?? json['temperature'] as num?;
    final num? rawPh = source['pH'] as num? ??
        source['ph'] as num? ??
        json['pH'] as num? ??
        json['ph'] as num?;
    final num? rawCond = source['electrical_conductivity'] as num? ??
        source['conductivity'] as num? ??
        json['electrical_conductivity'] as num? ??
        json['conductivity'] as num?;

    final double temp = (rawTemp ?? 38.5).toDouble();
    final double phVal = (rawPh ?? 6.65).toDouble();
    final double condVal = (rawCond ?? 4.80).toDouble();

    String rawTime = source['detection_time']?.toString() ??
        source['reading_time']?.toString() ??
        json['detection_time']?.toString() ??
        json['reading_time']?.toString() ??
        json['timestamp']?.toString() ??
        '';
    String formattedTime = rawTime;

    if (rawTime.isNotEmpty) {
      final parsed = DateTime.tryParse(rawTime);
      if (parsed != null) {
        final local = parsed.toLocal();
        final year = local.year.toString().padLeft(4, '0');
        final month = local.month.toString().padLeft(2, '0');
        final day = local.day.toString().padLeft(2, '0');
        final hour = local.hour.toString().padLeft(2, '0');
        final minute = local.minute.toString().padLeft(2, '0');
        formattedTime = '$year-$month-$day $hour:$minute';
      }
    }

    final String tag = json['cow_tag']?.toString() ??
        source['cow_tag']?.toString() ??
        json['tag_number']?.toString() ??
        source['tag_number']?.toString() ??
        json['tagNumber']?.toString() ??
        '';

    return DetectionResult(
      tagNumber: tag,
      timestamp: formattedTime.isEmpty ? 'Just now' : formattedTime,
      temperature: temp,
      pH: phVal,
      conductivity: condVal,
      status: isMastitisPresent ? StatusType.atRisk : StatusType.healthy,
      predictionLabel: prediction,
    );
  }

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
  final int alertId;
  final int resultId;
  final int farmerId;
  final String message;
  final String status;
  final String sendTime;
  final String id;
  final String tagNumber;
  final String timestamp;
  final bool isUnread;

  const AlertNotification({
    this.alertId = 0,
    this.resultId = 0,
    this.farmerId = 0,
    this.message = '',
    this.status = 'Unread',
    this.sendTime = '',
    required this.id,
    required this.tagNumber,
    required this.timestamp,
    required this.isUnread,
  });

  /// Helper property to extract and return the cow tag from the message string.
  /// Handles prefixes like "COW-009: Mastitis Present" or embedded patterns like "Cow COW-009".
  String get cowTag {
    if (tagNumber.isNotEmpty && tagNumber != 'Unknown Cow') {
      return tagNumber;
    }
    if (message.isNotEmpty) {
      if (message.contains(':')) {
        final prefix = message.split(':').first.trim();
        if (prefix.isNotEmpty && !prefix.toLowerCase().contains('urgent') && !prefix.toLowerCase().contains('alert')) {
          return prefix;
        }
      }
      final regex = RegExp(r'\b(COW[-\s]?\d+|Tag[-\s]?\d+)\b', caseSensitive: false);
      final match = regex.firstMatch(message);
      if (match != null) {
        return match.group(1)!;
      }
    }
    return tagNumber.isNotEmpty ? tagNumber : 'Cow Alert';
  }

  StatusType get badgeState => isUnread ? StatusType.atRisk : StatusType.healthy;
  String get badgeLabel => isUnread ? 'Unread' : 'Read';

  AlertNotification copyWith({
    int? alertId,
    int? resultId,
    int? farmerId,
    String? message,
    String? status,
    String? sendTime,
    String? id,
    String? tagNumber,
    String? timestamp,
    bool? isUnread,
  }) {
    return AlertNotification(
      alertId: alertId ?? this.alertId,
      resultId: resultId ?? this.resultId,
      farmerId: farmerId ?? this.farmerId,
      message: message ?? this.message,
      status: status ?? (isUnread != null ? (isUnread ? 'Unread' : 'Read') : this.status),
      sendTime: sendTime ?? this.sendTime,
      id: id ?? this.id,
      tagNumber: tagNumber ?? this.tagNumber,
      timestamp: timestamp ?? this.timestamp,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    final int aId = json['alert_id'] is int
        ? json['alert_id'] as int
        : (int.tryParse(json['alert_id']?.toString() ?? json['id']?.toString() ?? '') ?? 0);
    final int rId = json['result_id'] is int
        ? json['result_id'] as int
        : (int.tryParse(json['result_id']?.toString() ?? '') ?? 0);
    final int fId = json['farmer_id'] is int
        ? json['farmer_id'] as int
        : (int.tryParse(json['farmer_id']?.toString() ?? '') ?? 0);
    final String msg = json['message']?.toString() ?? '';
    final String statusStr = json['status']?.toString() ?? (json['isUnread'] == false ? 'Read' : 'Unread');
    final bool isUnread = statusStr.toLowerCase() == 'unread' || json['isUnread'] == true;
    final String rawTime = json['send_time']?.toString() ?? json['timestamp']?.toString() ?? '';

    // Extract cow tag from direct field or message
    String extractedTag = json['cow_tag']?.toString() ?? json['tagNumber']?.toString() ?? '';
    if (extractedTag.isEmpty && msg.isNotEmpty) {
      if (msg.contains(':')) {
        final prefix = msg.split(':').first.trim();
        if (prefix.isNotEmpty && !prefix.toLowerCase().contains('urgent') && !prefix.toLowerCase().contains('alert')) {
          extractedTag = prefix;
        }
      }
      if (extractedTag.isEmpty) {
        final match = RegExp(r'\b(COW[-\s]?\d+|Tag[-\s]?\d+)\b', caseSensitive: false).firstMatch(msg);
        if (match != null) {
          extractedTag = match.group(1)!;
        }
      }
    }
    if (extractedTag.isEmpty) {
      extractedTag = 'Unknown Cow';
    }

    String formattedTimestamp = rawTime;
    final parsed = DateTime.tryParse(rawTime);
    if (parsed != null) {
      final local = parsed.toLocal();
      final year = local.year.toString().padLeft(4, '0');
      final month = local.month.toString().padLeft(2, '0');
      final day = local.day.toString().padLeft(2, '0');
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      formattedTimestamp = '$year-$month-$day $hour:$minute';
    } else if (formattedTimestamp.length >= 16 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}').hasMatch(formattedTimestamp)) {
      formattedTimestamp = formattedTimestamp.substring(0, 16).replaceFirst('T', ' ');
    }

    return AlertNotification(
      alertId: aId,
      resultId: rId,
      farmerId: fId,
      message: msg,
      status: statusStr,
      sendTime: rawTime,
      id: aId > 0 ? aId.toString() : (json['id']?.toString() ?? ''),
      tagNumber: extractedTag,
      timestamp: formattedTimestamp,
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
        timestamp: '2026-09-08 14:30',
        isUnread: true,
      ),
      const AlertNotification(
        id: 'a2',
        tagNumber: 'Tag 105',
        timestamp: '2026-09-07 10:15',
        isUnread: true,
      ),
      const AlertNotification(
        id: 'a3',
        tagNumber: 'Tag 101',
        timestamp: '2026-09-05 08:45',
        isUnread: false,
      ),
      const AlertNotification(
        id: 'a4',
        tagNumber: 'Tag 104',
        timestamp: '2026-09-04 16:20',
        isUnread: false,
      ),
      const AlertNotification(
        id: 'a5',
        tagNumber: 'Tag 103',
        timestamp: '2026-09-03 11:00',
        isUnread: false,
      ),
    ];
  }
}
