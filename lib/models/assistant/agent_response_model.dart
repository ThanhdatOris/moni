import 'package:moni/constants/enums.dart';

/// Response model for Global Agent API
class AgentResponse {
  final AgentResponseStatus status;
  final AgentResponseType type;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;
  final DateTime timestamp;

  AgentResponse({
    required this.status,
    required this.type,
    required this.message,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a successful response
  factory AgentResponse.success({
    required String message,
    required AgentResponseType type,
    Map<String, dynamic>? data,
  }) {
    return AgentResponse(
      status: AgentResponseStatus.success,
      type: type,
      message: message,
      data: data,
    );
  }

  /// Create an error response
  factory AgentResponse.error(String errorMessage) {
    return AgentResponse(
      status: AgentResponseStatus.error,
      type: AgentResponseType.error,
      message: errorMessage,
      error: errorMessage,
    );
  }

  /// Create a pending response
  factory AgentResponse.pending({
    required String message,
    required AgentResponseType type,
  }) {
    return AgentResponse(
      status: AgentResponseStatus.pending,
      type: type,
      message: message,
    );
  }

  /// Check if response is successful
  bool get isSuccess => status == AgentResponseStatus.success;

  /// Check if response is error
  bool get isError => status == AgentResponseStatus.error;

  /// Check if response is pending
  bool get isPending => status == AgentResponseStatus.pending;

  /// Get data with type safety
  T? getData<T>(String key) {
    if (data == null) return null;
    final value = data![key];
    return value is T ? value : null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'type': type.name,
      'message': message,
      'data': data,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      status: AgentResponseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AgentResponseStatus.error,
      ),
      type: AgentResponseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AgentResponseType.text,
      ),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'AgentResponse(status: $status, type: $type, message: $message)';
  }
}
