import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/app_data.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  
  BluetoothDevice? _selectedDevice;
  PaperSize _paperSize = PaperSize.mm58;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  PaperSize get paperSize => _paperSize;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString('printer_mac');
    final savedSize = prefs.getInt('printer_size') ?? 58;
    
    _paperSize = savedSize == 80 ? PaperSize.mm80 : PaperSize.mm58;

    if (savedMac != null) {
      final devices = await bluetooth.getBondedDevices();
      try {
        _selectedDevice = devices.firstWhere((d) => d.address == savedMac);
      } catch (_) {}
    }
  }

  Future<void> saveSettings(BluetoothDevice device, int size) async {
    _selectedDevice = device;
    _paperSize = size == 80 ? PaperSize.mm80 : PaperSize.mm58;
    
    final prefs = await SharedPreferences.getInstance();
    if (device.address != null) {
      await prefs.setString('printer_mac', device.address!);
    }
    await prefs.setInt('printer_size', size);
  }

  String? lastError;

  Future<bool> connect() async {
    if (_selectedDevice == null) {
      lastError = 'Tidak ada printer yang dipilih di pengaturan aplikasi';
      return false;
    }
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == true) return true;
    
    try {
      await bluetooth.connect(_selectedDevice!);
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      lastError = 'Gagal koneksi: $e';
      return false;
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }

  Future<bool> printReceipt(OrderData order, ShopData settings) async {
    if (!await connect()) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(_paperSize, profile);
      List<int> bytes = [];

      bytes += generator.text(settings.name, styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
      if (settings.address.isNotEmpty) bytes += generator.text(settings.address, styles: const PosStyles(align: PosAlign.center));
      if (settings.phone.isNotEmpty) bytes += generator.text('WA: ${settings.phone}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Sistem Manajemen Laundry', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(1);

      bytes += generator.row([
        PosColumn(text: 'No. Order:', width: 4),
        PosColumn(text: order.id, width: 8, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Pelanggan:', width: 4),
        PosColumn(text: order.customer, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      if (order.phone.isNotEmpty) {
        bytes += generator.row([
          PosColumn(text: 'Telepon:', width: 4),
          PosColumn(text: order.phone, width: 8, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.row([
        PosColumn(text: 'Layanan:', width: 4),
        PosColumn(text: order.service, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      final unit = order.service.toLowerCase() == 'satuan' ? 'pcs' : 'kg';
      bytes += generator.row([
        PosColumn(text: 'Berat/Jml:', width: 4),
        PosColumn(text: '${order.weight} $unit', width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      bytes += generator.row([
        PosColumn(text: 'Harga/Unit:', width: 4),
        PosColumn(text: fmt.format(order.pricePerUnit), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: fmt.format(order.price), width: 8, styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2)),
      ]);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.row([
        PosColumn(text: 'Tgl Masuk:', width: 4),
        PosColumn(text: DateFormat('dd/MM/yy HH:mm').format(order.orderTime), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Estimasi:', width: 4),
        PosColumn(text: order.estimatedDate, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kasir/PIC:', width: 4),
        PosColumn(text: order.picName, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (order.notes.isNotEmpty) {
        bytes += generator.emptyLines(1);
        bytes += generator.text('Catatan:', styles: const PosStyles(bold: true));
        bytes += generator.text(order.notes);
      }

      bytes += generator.emptyLines(1);
      
      // Barcode
      final List<int> barData = order.id.codeUnits;
      bytes += generator.barcode(Barcode.code128(barData), height: 50);
      bytes += generator.text(order.id, styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.emptyLines(1);
      bytes += generator.text(settings.receiptFooter, styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Harap bawa struk ini saat', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('pengambilan pakaian.', styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      await bluetooth.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      lastError = 'Gagal print: $e';
      return false;
    }
  }
}
