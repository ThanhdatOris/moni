import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum cho loại báo cáo
enum ReportType {
  byTime,
  byCategory;

  String get value {
    switch (this) {
      case ReportType.byTime:
        return 'BY_TIME';
      case ReportType.byCategory:
        return 'BY_CATEGORY';
    }
  }

  static ReportType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BY_TIME':
        return ReportType.byTime;
      case 'BY_CATEGORY':
        return ReportType.byCategory;
      default:
        throw ArgumentError('Loại báo cáo không hợp lệ: $value');
    }
  }
}

/// Enum cho khoảng thời gian báo cáo
enum TimePeriod {
  monthly,
  quarterly,
  yearly;

  String get value {
    switch (this) {
      case TimePeriod.monthly:
        return 'MONTHLY';
      case TimePeriod.quarterly:
        return 'QUARTERLY';
      case TimePeriod.yearly:
        return 'YEARLY';
    }
  }

  static TimePeriod fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MONTHLY':
        return TimePeriod.monthly;
      case 'QUARTERLY':
        return TimePeriod.quarterly;
      case 'YEARLY':
        return TimePeriod.yearly;
      default:
        throw ArgumentError('Khoảng thời gian báo cáo không hợp lệ: $value');
    }
  }
}

/// Model đại diện cho báo cáo tài chính
class ReportModel {
  final String reportId;
  final String userId;
  final ReportType type;
  final TimePeriod timePeriod;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.reportId,
    required this.userId,
    required this.type,
    required this.timePeriod,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tạo ReportModel từ Map
  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      reportId: id,
      userId: map['user_id'] ?? '',
      type: ReportType.fromString(map['type'] ?? 'BY_TIME'),
      timePeriod: TimePeriod.fromString(map['time_period'] ?? 'MONTHLY'),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Chuyển ReportModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type.value,
      'time_period': timePeriod.value,
      'data': data,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Tạo bản sao ReportModel với một số trường được cập nhật
  ReportModel copyWith({
    String? reportId,
    String? userId,
    ReportType? type,
    TimePeriod? timePeriod,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timePeriod: timePeriod ?? this.timePeriod,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReportModel(reportId: $reportId, userId: $userId, type: $type, timePeriod: $timePeriod, data: $data, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReportModel &&
        other.reportId == reportId &&
        other.userId == userId &&
        other.type == type &&
        other.timePeriod == timePeriod &&
        other.data.toString() == data.toString() &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return reportId.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        timePeriod.hashCode ^
        data.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
