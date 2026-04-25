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
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
      final sep = '================================';
      final sepLight = '--------------------------------';

      // ===== HEADER =====
      bytes += generator.text(settings.name,
          styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
      if (settings.address.isNotEmpty)
        bytes += generator.text(settings.address, styles: const PosStyles(align: PosAlign.center));
      if (settings.phone.isNotEmpty)
        bytes += generator.text('WA: ${settings.phone}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(sepLight, styles: const PosStyles(align: PosAlign.center));

      // ===== NAMA PELANGGAN BESAR (seperti nota referensi) =====
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        order.customer.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.left,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      if (order.phone.isNotEmpty)
        bytes += generator.text(
          order.phone,
          styles: const PosStyles(align: PosAlign.left, height: PosTextSize.size2, bold: true),
        );
      bytes += generator.emptyLines(1);
      bytes += generator.text(sepLight, styles: const PosStyles(align: PosAlign.center));

      // ===== TANGGAL & INFO =====
      bytes += generator.row([
        PosColumn(text: 'Tgl Terima :', width: 6),
        PosColumn(text: DateFormat('dd/MM/yy HH:mm').format(order.orderTime), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Est Selesai:', width: 6),
        PosColumn(text: order.estimatedDate, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'No. Order  :', width: 6),
        PosColumn(text: order.id, width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));

      // ===== CATATAN =====
      bytes += generator.text('CATATAN :', styles: const PosStyles(bold: true));
      bytes += generator.text(order.notes.isNotEmpty ? order.notes : '-');
      bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));

      // ===== LAYANAN =====
      bytes += generator.emptyLines(1);
      
      if (order.items.isNotEmpty) {
        bytes += generator.text('LAYANAN:', styles: const PosStyles(bold: true));
        bytes += generator.emptyLines(1);
        for (final item in order.items) {
          bytes += generator.text(item.service.toUpperCase(), styles: const PosStyles(bold: true));
          bytes += generator.row([
            PosColumn(text: '  ${item.displayQty}', width: 7),
            PosColumn(text: fmt.format(item.subtotal), width: 5, styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
      } else {
        final unit = order.service.toLowerCase() == 'satuan' ? 'pcs' : 'Kg';
        bytes += generator.text(
          order.service.toUpperCase(),
          styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
        );
        bytes += generator.row([
          PosColumn(text: '  @${order.weight} $unit', width: 7),
          PosColumn(text: fmt.format(order.price), width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.emptyLines(1);
      bytes += generator.text(sepLight, styles: const PosStyles(align: PosAlign.center));

      // ===== TOTAL =====
      bytes += generator.row([
        PosColumn(text: 'Sub-total', width: 7),
        PosColumn(text: fmt.format(order.price), width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Grand Total', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: fmt.format(order.price), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Bayar', width: 7),
        PosColumn(
          text: order.paymentStatus == 'Lunas' ? '${fmt.format(order.price)} (LUNAS)' : 'BELUM LUNAS',
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      bytes += generator.text(sep, styles: const PosStyles(align: PosAlign.center));

      // ===== BARCODE =====
      bytes += generator.emptyLines(1);
      bytes += generator.text('- SCAN ME -', styles: const PosStyles(align: PosAlign.center, bold: true));
      // Code 128 requires a subset prefix. '{B' is for Subset B (Alphanumeric)
      final List<int> barData = [123, 66, ...order.id.codeUnits]; 
      bytes += generator.barcode(Barcode.code128(barData), height: 60);
      bytes += generator.text(order.id, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(1);

      // ===== FOOTER =====
      bytes += generator.text(settings.receiptFooter, styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Harap bawa struk saat pengambilan.', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(3);
      bytes += generator.cut();

      await bluetooth.writeBytes(Uint8List.fromList(bytes));
      return true;
    } catch (e) {
      lastError = 'Gagal print: $e';
      return false;
    }
  }
}
