import 'package:flutter/material.dart';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer_service.dart';

class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrinterSettingsDialog(),
    );
  }

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isLoading = true;
  int _paperSize = 58;

  @override
  void initState() {
    super.initState();
    _paperSize = _printerService.paperSize.value == 80 ? 80 : 58;
    _selectedDevice = _printerService.selectedDevice;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      _devices = await _printerService.bluetooth.getBondedDevices();
      // If no device selected but there's a saved one in the list, select it
      if (_selectedDevice == null && _devices.isNotEmpty) {
        _selectedDevice = _devices.first;
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndConnect() async {
    if (_selectedDevice == null) return;
    
    setState(() => _isLoading = true);
    await _printerService.saveSettings(_selectedDevice!, _paperSize);
    final connected = await _printerService.connect();
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terhubung ke ${_selectedDevice!.name}', style: TextStyle()), backgroundColor: const Color(0xFF2E7D32)));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal terhubung ke ${_selectedDevice!.name}', style: TextStyle()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengaturan Printer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1C2E))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          
          Text('Ukuran Kertas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _radioCard('58mm', 58, _paperSize, () => setState(() => _paperSize = 58)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _radioCard('80mm', 80, _paperSize, () => setState(() => _paperSize = 80)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pilih Printer Bluetooth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              GestureDetector(
                onTap: _loadDevices,
                child: const Icon(Icons.refresh, color: Color(0xFF0D47A1), size: 20),
              )
            ],
          ),
          const SizedBox(height: 8),
          
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_devices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(14)),
              child: Text('Tidak ada perangkat Bluetooth yang terpasang. Harap pair printer Anda di pengaturan Bluetooth HP.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (ctx, i) {
                  final d = _devices[i];
                  final sel = _selectedDevice?.address == d.address;
                  return ListTile(
                    title: Text(d.name ?? 'Unknown Device', style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(d.address ?? '', style: TextStyle(fontSize: 11)),
                    trailing: sel ? const Icon(Icons.check_circle, color: Color(0xFF0D47A1)) : null,
                    onTap: () => setState(() => _selectedDevice = d),
                  );
                },
              ),
            ),
            
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedDevice == null || _isLoading ? null : _saveAndConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan & Hubungkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _radioCard(String label, int value, int groupValue, VoidCallback onTap) {
    bool sel = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? const Color(0xFF1E88E5) : Colors.grey.shade200, width: sel ? 2 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: sel ? const Color(0xFF1565C0) : Colors.grey.shade600))),
      ),
    );
  }
}



