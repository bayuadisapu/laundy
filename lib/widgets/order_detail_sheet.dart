import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_data.dart';
import '../services/printer_service.dart';
import '../services/void_approval_service.dart';
import '../services/audit_service.dart';
import '../screens/printer_settings_dialog.dart';

class OrderDetailSheet extends StatefulWidget {
  final OrderData order;
  final AppState appState;
  final bool isAdmin;
  final Function(OrderData) onUpdateOrder;
  final Function(OrderData)? onDeleteOrder;
  final Function(String)? onCancelPickup;
  final VoidCallback? onRefresh;

  const OrderDetailSheet({
    super.key,
    required this.order,
    required this.appState,
    required this.isAdmin,
    required this.onUpdateOrder,
    this.onDeleteOrder,
    this.onCancelPickup,
    this.onRefresh,
  });

  static void show(
    BuildContext context, {
    required OrderData order,
    required AppState appState,
    required bool isAdmin,
    required Function(OrderData) onUpdateOrder,
    Function(OrderData)? onDeleteOrder,
    Function(String)? onCancelPickup,
    VoidCallback? onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (ctx) => OrderDetailSheet(
        order: order,
        appState: appState,
        isAdmin: isAdmin,
        onUpdateOrder: onUpdateOrder,
        onDeleteOrder: onDeleteOrder,
        onCancelPickup: onCancelPickup,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  final PrinterService _printerService = PrinterService();
  bool _isPrinting = false;

  String _fmt(double v) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

  Future<void> _sendWhatsApp() async {
    if (widget.order.phone.isEmpty) return;
    final phone = widget.order.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    final msg = _defaultWaMessage(widget.order);
    final uri = Uri.parse('https://wa.me/$intlPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _defaultWaMessage(OrderData order) {
    switch (order.status) {
      case 'Selesai':
        return '🧺 Halo *${order.customer}*!\n\nCucian Anda sudah *SELESAI* dan siap diambil. 🎉\n\n'
          '🆔 Order: *${order.id}*\n📦 Layanan: ${order.service}\n⚖️ Berat: ${order.weight} kg\n💰 Total: *${order.formattedPrice}*\n\n'
          'Silakan datang ke toko kami. Terima kasih sudah mempercayakan cucian Anda kepada kami! 🙏';
      case 'Proses':
        return '🧺 Halo *${order.customer}*!\n\nCucian Anda dengan ID *${order.id}* sedang dalam proses pengerjaan.\n\n'
          '📦 Layanan: ${order.service}\n⚖️ Berat: ${order.weight} kg\n📅 Estimasi: ${order.estimatedDate}\n\nHarap ditunggu ya! Kami akan segera memberi kabar. 🙏';
      case 'Sudah Diambil':
        return '🧺 Halo *${order.customer}*!\n\nTerima kasih sudah mempercayakan laundry Anda kepada kami. 😊\nSampai jumpa lagi!';
      default:
        return '🧺 Halo *${order.customer}*! Info pesanan *${order.id}*: Status saat ini *${order.status}*.';
    }
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      final success = await _printerService.printReceipt(widget.order, widget.appState.currentShop);
      if (!mounted) return;
      if (!success) {
        _showPrinterError(_printerService.lastError ?? 'Gagal mencetak struk');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showPrinterError(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masalah Printer'),
        content: Text(error),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PrinterSettingsDialog.show(context);
            },
            child: const Text('Pengaturan Printer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoid() async {
    final reason = await VoidApprovalService.requestApproval(
      context, 
      title: 'Konfirmasi Void', 
      message: 'Apakah Anda yakin ingin membatalkan pesanan ${widget.order.id}? Tindakan ini akan dicatat di log audit.',
    );

    if (reason != null) {
      try {
        widget.onUpdateOrder(widget.order.copyWith(status: 'Void'));
        await AuditService().log(AuditLog(
          id: '', 
          action: AuditActionType.void_order,
          orderId: widget.order.id,
          staffId: widget.appState.currentUser?.id ?? '',
          oldData: {'status': widget.order.status},
          newData: {'status': 'Void'},
          reason: reason,
        ));
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil di-void')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal void: $e')));
      }
    }
  }

  void _confirmCancelPickup() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Batalkan Checkout?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Status pesanan ${widget.order.id} akan kembali ke "Selesai". Gunakan ini jika checkout dilakukan tidak sengaja.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () { 
            Navigator.pop(ctx); 
            widget.onCancelPickup?.call(widget.order.id);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout dibatalkan untuk ${widget.order.id}'), backgroundColor: Colors.orange));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _confirmDelete() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Hapus Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Pesanan ${widget.order.id} (${widget.order.customer}) akan dihapus permanen.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () { 
            Navigator.pop(ctx); 
            widget.onDeleteOrder?.call(widget.order);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan ${widget.order.id} dihapus'), backgroundColor: Colors.red));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withAlpha(220), Colors.white.withAlpha(180)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(top: 100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: Colors.blue.withAlpha(20), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 200, duration: 15.seconds, curve: Curves.easeInOut)),
          Positioned(bottom: 200, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.orange.withAlpha(15), shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: -150, duration: 18.seconds, curve: Curves.easeInOut)),

          SafeArea(
            child: Column(
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 48),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Detail Pesanan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E), letterSpacing: -1.5)),
                            Text(order.id, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade800, letterSpacing: 1)),
                          ]),
                        ),
                        IconButton(
                          onPressed: () => PrinterSettingsDialog.show(context),
                          icon: const Icon(Icons.settings_bluetooth_rounded, color: Colors.blue),
                          tooltip: 'Pengaturan Printer',
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withAlpha(10), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 26)),
                        ),
                      ]),
                      const SizedBox(height: 32),

                      Row(children: [
                        Expanded(child: _infoCard(Icons.person_outline_rounded, 'PELANGGAN', [
                          Text(order.customer, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                          const SizedBox(height: 6),
                          Text(order.phone.isEmpty ? 'No Phone' : order.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ])),
                        const SizedBox(width: 20),
                        Expanded(child: _infoCard(Icons.local_laundry_service_outlined, 'LAYANAN', [
                          Text(order.service, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                          const SizedBox(height: 6),
                          Text('${order.weight} kg', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ])),
                      ]),
                      const SizedBox(height: 20),

                      _infoCard(Icons.auto_graph_rounded, 'STATUS & PROGRES', [
                        _statusSelector(order, (status) {
                          widget.onUpdateOrder(order.copyWith(status: status));
                          Navigator.pop(context);
                        }),
                        const SizedBox(height: 12),
                        _infoRow('Estimasi', order.estimatedDate),
                        _infoRow('Dibuat', DateFormat('dd MMM yyyy, HH:mm').format(order.orderTime)),
                        if (order.notes.isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.sticky_note_2_rounded, size: 18, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(child: Text('CATATAN: ${order.notes}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade900))),
                          ]),
                        ],
                      ]),
                      const SizedBox(height: 20),

                      _infoCard(Icons.payments_outlined, 'DETAIL PEMBAYARAN', [
                        _infoRow('Total Tagihan', _fmt(order.price.toDouble()), color: const Color(0xFF0D47A1), large: true),
                      ]),
                      const SizedBox(height: 20),

                      _infoCard(Icons.assignment_ind_outlined, 'PENUGASAN STAF', [
                        if (widget.isAdmin) ...[
                          _picSelector('Tukang Cuci', order.picWashName, (s) {
                            widget.onUpdateOrder(order.copyWith(picWashId: s.id, picWashName: s.name));
                            Navigator.pop(context);
                          }),
                          _picSelector('Tukang Setrika', order.picIronName, (s) {
                            widget.onUpdateOrder(order.copyWith(picIronId: s.id, picIronName: s.name));
                            Navigator.pop(context);
                          }),
                          _picSelector('Tukang Pack', order.picPackName, (s) {
                            widget.onUpdateOrder(order.copyWith(picPackId: s.id, picPackName: s.name));
                            Navigator.pop(context);
                          }),
                        ] else ...[
                          _infoRow('Tukang Cuci', order.picWashName ?? '-'),
                          _infoRow('Tukang Setrika', order.picIronName ?? '-'),
                          _infoRow('Tukang Pack', order.picPackName ?? '-'),
                        ]
                      ]),

                      const SizedBox(height: 32),

                      // Print Receipt CTA
                      SizedBox(
                        width: double.infinity, height: 64,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                            boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withAlpha(40), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isPrinting ? null : _handlePrint,
                            icon: _isPrinting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.print_rounded, size: 22),
                            label: Text(_isPrinting ? 'MENCETAK...' : 'CETAK STRUK SEKARANG', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, foregroundColor: Colors.white, 
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (order.phone.isNotEmpty) ...[SizedBox(
                        width: double.infinity, height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () { Navigator.pop(context); _sendWhatsApp(); },
                          icon: const Icon(Icons.chat_rounded, size: 20),
                          label: Text(
                            order.status == 'Selesai' ? 'Beritahu Cucian Siap Diambil' : 'Hubungi via WhatsApp',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ), const SizedBox(height: 16)],

                      if (widget.isAdmin) ...[
                        Row(children: [
                          if (order.status != 'Sudah Diambil')
                            Expanded(child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)]),
                                boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _handleVoid,
                                icon: const Icon(Icons.block_rounded, size: 20),
                                label: const Text('VOID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              ),
                            )),
                          if (order.status != 'Sudah Diambil') const SizedBox(width: 16),
                          if (order.status == 'Sudah Diambil')
                            Expanded(child: SizedBox(height: 64, child: OutlinedButton.icon(
                              onPressed: _confirmCancelPickup,
                              icon: const Icon(Icons.history_rounded, size: 20),
                              label: const Text('Undo Checkout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE65100), side: const BorderSide(color: Color(0xFFE65100), width: 2.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            ))),
                          Expanded(child: SizedBox(height: 64, child: TextButton.icon(
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.black38),
                            label: const Text('Hapus', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w700, fontSize: 16)),
                            style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          ))),
                        ]),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(120),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(150), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF0D47A1).withAlpha(150)),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0D47A1).withAlpha(180), letterSpacing: 1)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String l, String v, {bool bold = false, Color? color, bool large = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      const SizedBox(width: 16),
      Flexible(child: Text(v, style: TextStyle(fontSize: large ? 16 : 13, fontWeight: bold || large ? FontWeight.w900 : FontWeight.w700, color: color ?? const Color(0xFF1A1C1E)), textAlign: TextAlign.end)),
    ]),
  );

  Widget _statusSelector(OrderData order, Function(String) onSelect) {
    Color sc; Color sb; IconData si;
    switch (order.status) {
      case 'Proses': sc = const Color(0xFFE65100); sb = const Color(0xFFFFF3E0); si = Icons.sync_rounded; break;
      case 'Selesai': sc = const Color(0xFF1E88E5); sb = const Color(0xFFE3F2FD); si = Icons.check_circle_outline_rounded; break;
      case 'Sudah Diambil': sc = const Color(0xFF2E7D32); sb = const Color(0xFFE8F5E9); si = Icons.inventory_2_outlined; break;
      default: sc = Colors.grey; sb = Colors.grey.shade100; si = Icons.help_outline_rounded;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status Progres', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          PopupMenuButton<String>(
            onSelected: onSelect,
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            itemBuilder: (ctx) => [
              _buildPopupItem('Proses', Icons.sync_rounded, const Color(0xFFE65100)),
              _buildPopupItem('Selesai', Icons.check_circle_outline_rounded, const Color(0xFF1E88E5)),
              if (widget.isAdmin) _buildPopupItem('Sudah Diambil', Icons.inventory_2_outlined, const Color(0xFF2E7D32)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sb.withAlpha(200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sc.withAlpha(50), width: 1.5),
                boxShadow: [BoxShadow(color: sc.withAlpha(20), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(si, size: 14, color: sc),
                  const SizedBox(width: 8),
                  Text(order.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: sc, letterSpacing: 0.2)),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: sc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _picSelector(String label, String? current, Function(StaffData) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<StaffData>(
                onSelected: onSelect,
                offset: const Offset(0, 35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 8,
                itemBuilder: (ctx) => widget.appState.staffList.map((s) => PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundImage: NetworkImage(s.imgUrl.isNotEmpty ? s.imgUrl : 'https://i.pravatar.cc/150?u=${s.id}'), backgroundColor: Colors.grey.shade200),
                      const SizedBox(width: 12),
                      Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withAlpha(20))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(current ?? 'Pilih Staf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: current == null ? Colors.grey : Colors.black)),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
