import 'package:flutter/material.dart';

/// Service để tối ưu UI Assistant, đặc biệt cho chat interface
class UIOptimizationService extends ChangeNotifier {
  static final UIOptimizationService _instance =
      UIOptimizationService._internal();
  factory UIOptimizationService() => _instance;
  UIOptimizationService._internal();

  bool _isChatFocused = false;
  bool _isTyping = false;
  bool _isInAssistantChatMode = false;
  String _activeModule = 'analytics';

  // Getters
  bool get isChatFocused => _isChatFocused;
  bool get isTyping => _isTyping;
  bool get isInAssistantChatMode => _isInAssistantChatMode;
  String get activeModule => _activeModule;

  /// Xác định có nên ẩn menubar không - ẩn khi ở Assistant Chat mode
  bool get shouldHideMenubar => _isInAssistantChatMode;

  /// Xác định có nên giảm spacing bottom không (khi menubar ẩn)
  bool get shouldReduceBottomSpacing => shouldHideMenubar;

  /// Set chat focus state
  void setChatFocused(bool focused) {
    if (_isChatFocused != focused) {
      _isChatFocused = focused;
      notifyListeners();
    }
  }

  /// Set typing state
  void setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      notifyListeners();
    }
  }

  /// Set active module
  void setActiveModule(String module) {
    if (_activeModule != module) {
      _activeModule = module;
      // Reset chat states khi không ở chat module
      if (module != 'chatbot') {
        _isChatFocused = false;
        _isTyping = false;
        _isInAssistantChatMode = false;
      }
      notifyListeners();
    }
  }

  /// Enter Assistant Chat mode - ẩn menubar
  void enterAssistantChatMode() {
    if (!_isInAssistantChatMode) {
      _isInAssistantChatMode = true;
      notifyListeners();
    }
  }

  /// Exit Assistant Chat mode - hiện lại menubar
  void exitAssistantChatMode() {
    if (_isInAssistantChatMode) {
      _isInAssistantChatMode = false;
      notifyListeners();
    }
  }

  /// Get bottom spacing phù hợp
  double getBottomSpacing() {
    if (shouldReduceBottomSpacing) {
      return 20.0; // Spacing nhỏ khi menubar ẩn
    }
    return 120.0; // Spacing bình thường cho menubar
  }

  /// Reset tất cả states
  void reset() {
    _isChatFocused = false;
    _isTyping = false;
    _isInAssistantChatMode = false;
    _activeModule = 'analytics';
    notifyListeners();
  }
}
