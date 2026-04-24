import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoidApprovalService {
  static const String _pinKey = 'void_pin';
  static const String _defaultPin = '1234';

  static Future<String> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) ?? _defaultPin;
  }

  static Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, newPin);
  }

  static Future<String?> requestApproval(BuildContext context, {required String title, required String message}) async {
    final pinController = TextEditingController();
    final reasonController = TextEditingController();
    String? result;
    String? pinError;

    final adminPin = await getPin();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('PIN ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '****',
                  errorText: pinError,
                ),
                onChanged: (_) => setModal(() => pinError = null),
              ),
              const SizedBox(height: 16),
              const Text('ALASAN VOID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Contoh: Salah input'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                if (pinController.text == adminPin) {
                  result = reasonController.text.isEmpty ? 'Void oleh Admin' : reasonController.text;
                  Navigator.pop(ctx);
                } else {
                  setModal(() => pinError = 'PIN salah!');
                }
              },
              child: const Text('SETUJUI'),
            ),
          ],
        ),
      ),
    );

    return result;
  }
}
