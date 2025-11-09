import 'package:moni/constants/enums.dart';

/// Request model for Global Agent API
class AgentRequest {
  final AgentRequestType type;
  final String message;
  final Map<String, dynamic>? parameters;
  final String? conversationId;
  final DateTime timestamp;

  AgentRequest({
    required this.type,
    required this.message,
    this.parameters,
    this.conversationId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a chat request
  factory AgentRequest.chat({
    required String message,
    String? conversationId,
    Map<String, dynamic>? parameters,
  }) {
    return AgentRequest(
      type: AgentRequestType.chat,
      message: message,
      conversationId: conversationId,
      parameters: parameters,
    );
  }

  /// Create an analytics request
  factory AgentRequest.analytics({
    required String message,
    Map<String, dynamic>? parameters,
  }) {
    return AgentRequest(
      type: AgentRequestType.analytics,
      message: message,
      parameters: parameters,
    );
  }

  /// Create a budget request
  factory AgentRequest.budget({
    required String message,
    Map<String, dynamic>? parameters,
  }) {
    return AgentRequest(
      type: AgentRequestType.budget,
      message: message,
      parameters: parameters,
    );
  }

  /// Create a report request
  factory AgentRequest.report({
    required String message,
    Map<String, dynamic>? parameters,
  }) {
    return AgentRequest(
      type: AgentRequestType.report,
      message: message,
      parameters: parameters,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'parameters': parameters,
      'conversationId': conversationId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AgentRequest.fromJson(Map<String, dynamic> json) {
    return AgentRequest(
      type: AgentRequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AgentRequestType.chat,
      ),
      message: json['message'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
      conversationId: json['conversationId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'AgentRequest(type: $type, message: $message, parameters: $parameters)';
  }
}
