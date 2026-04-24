import 'package:flutter/services.dart';
import 'dart:async';

class BarcodeScannerService {
  static final BarcodeScannerService _instance = BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  final _buffer = StringBuffer();
  DateTime? _lastTimestamp;
  static const _scannerSpeedThresholdMs = 50; 
  
  StreamController<String>? _scanController;
  
  void startListening(Function(String) onScan) {
    _scanController ??= StreamController<String>.broadcast();
    _scanController!.stream.listen(onScan);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void stopListening() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _scanController?.close();
    _scanController = null;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) return false;

    final now = DateTime.now();
    final char = event.character;
    
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_buffer.isNotEmpty) {
        final code = _buffer.toString();
        _buffer.clear();
        _scanController?.add(code);
      }
      return true; 
    }

    if (char != null && char.isNotEmpty) {
      if (_lastTimestamp != null) {
        final diff = now.difference(_lastTimestamp!).inMilliseconds;
        if (diff > _scannerSpeedThresholdMs) {
          _buffer.clear();
        }
      }
      _buffer.write(char);
      _lastTimestamp = now;
      return true; 
    }
    return false;
  }
}
