// models/weight_height_log.dart
class WeightHeightLog {
  final int id;                     // 0 for create, real id for update
  final double weight;
  final String weightUnitType;
  final double height;
  final String heightUnitType;

  WeightHeightLog({
    required this.id,
    required this.weight,
    required this.weightUnitType,
    required this.height,
    required this.heightUnitType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight,
    'weightUnitType': weightUnitType,
    'height': height,
    'heightUnitType': heightUnitType,
  };

  factory WeightHeightLog.fromJson(Map<String, dynamic> json) {
    return WeightHeightLog(
      id: json['id'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnitType: json['weightUnitType'] as String,
      height: (json['height'] as num).toDouble(),
      heightUnitType: json['heightUnitType'] as String,
    );
  }
}

/* ---------- Hero Dashboard ---------- */




enum ChangeType { increased, decreased, unchanged }

class BmiResponse {
  final bool success;
  final String message;
  final String? unit;
  final HeroDashboardData? data;

  const BmiResponse({
    required this.success,
    required this.message,
    this.unit,
    this.data,
  });

  factory BmiResponse.fromJson(Map<String, dynamic> json) {
    return BmiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      unit: json['unit'],
      data: json['data'] != null ? HeroDashboardData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'unit': unit,
    'data': data?.toJson(),
  };
}

class HeroDashboardData {
  final String? weight;
  final double? bmiValue;
  final String? bmiStatus;
  final DateTime? recordedAt;
  final ChangeInfo? last24Hours;
  final ChangeInfo? last48Hours;

  const HeroDashboardData({
    this.weight,
    this.bmiValue,
    this.bmiStatus,
    this.recordedAt,
    this.last24Hours,
    this.last48Hours,
  });

  factory HeroDashboardData.fromJson(Map<String, dynamic> json) {
    return HeroDashboardData(
      weight: json['weight'],
      bmiValue: (json['bmiValue'] as num?)?.toDouble(),
      bmiStatus: json['bmiStatus'],
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'])
          : null,
      last24Hours: json['last24Hours'] != null
          ? ChangeInfo.fromJson(json['last24Hours'])
          : null,
      last48Hours: json['last48Hours'] != null
          ? ChangeInfo.fromJson(json['last48Hours'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'bmiValue': bmiValue,
    'bmiStatus': bmiStatus,
    'recordedAt': recordedAt?.toIso8601String(),
    'last24Hours': last24Hours?.toJson(),
    'last48Hours': last48Hours?.toJson(),
  };
}

class ChangeInfo {
  final String? value;
  final ChangeType? changeType;

  const ChangeInfo({this.value, this.changeType});

  factory ChangeInfo.fromJson(Map<String, dynamic> json) {
    return ChangeInfo(
      value: json['value'],
      changeType: _parseChangeType(json['changeType']),
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'changeType': changeType?.name,
  };

  static ChangeType? _parseChangeType(String? type) {
    switch (type?.toLowerCase()) {
      case 'increased':
        return ChangeType.increased;
      case 'decreased':
        return ChangeType.decreased;
      case 'unchanged':
        return ChangeType.unchanged;
      default:
        return null;
    }
  }
}




/* ---------- Current Record ---------- */
class CurrentRecord {
  final String weight;
  final String height;
  final double bmiValue;
  final String bmiStatus;
  final String recordedAt;
  final int patientWeightHeightId;

  CurrentRecord({
    required this.weight,
    required this.height,
    required this.bmiValue,
    required this.bmiStatus,
    required this.recordedAt,
    required this.patientWeightHeightId,
  });

  factory CurrentRecord.fromJson(Map<String, dynamic> json) {
    return CurrentRecord(
      weight: json['weight'] as String,
      height: json['height'] as String,
      bmiValue: (json['bmiValue'] as num).toDouble(),
      bmiStatus: json['bmiStatus'] as String,
      recordedAt: json['recordedAt'] as String,
      patientWeightHeightId: json['patientWeightHeightId'] as int,
    );
  }
}

/* ---------- History Record ---------- */
class HistoryRecord {
  final String weight;
  final String height;
  final double bmiValue;
  final String bmiStatus;
  final String recordedAt;

  HistoryRecord({
    required this.weight,
    required this.height,
    required this.bmiValue,
    required this.bmiStatus,
    required this.recordedAt,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      weight: json['weight'] as String,
      height: json['height'] as String,
      bmiValue: (json['bmiValue'] as num).toDouble(),
      bmiStatus: json['bmiStatus'] as String,
      recordedAt: json['recordedAt'] as String,
    );
  }
}

/* ---------- Current + Past Wrapper ---------- */
class CurrentAndPastData {
  final CurrentRecord currentRecord;
  final List<HistoryRecord> history;
  final String weightUnit;
  final String heightUnit;

  CurrentAndPastData({
    required this.currentRecord,
    required this.history,
    required this.weightUnit,
    required this.heightUnit,
  });

  factory CurrentAndPastData.fromJson(Map<String, dynamic> json) {
    var historyList = (json['history'] as List)
        .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return CurrentAndPastData(
      currentRecord: CurrentRecord.fromJson(json['currentRecord']),
      history: historyList,
      weightUnit: json['weightUnit'] as String,
      heightUnit: json['heightUnit'] as String,
    );
  }
}