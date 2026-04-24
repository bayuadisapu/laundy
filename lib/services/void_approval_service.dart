import 'package:flutter/material.dart';

class VoidApprovalService {
  static Future<String?> requestApproval(BuildContext context, {required String title, required String message}) async {
    final pinController = TextEditingController();
    final reasonController = TextEditingController();
    String? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '****'),
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
              if (pinController.text == '1234') { // PIN Admin default
                result = reasonController.text.isEmpty ? 'Void oleh Admin' : reasonController.text;
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Salah!')));
              }
            },
            child: const Text('SETUJUI'),
          ),
        ],
      ),
    );

    return result;
  }
}
