import 'package:intl/intl.dart';

class PriceConfig {
  final int? id;
  final String service;
  final int pricePerUnit;
  final String unit;
  final int defaultDays;
  final String? shopId;

  PriceConfig({this.id, required this.service, required this.pricePerUnit, required this.unit, required this.defaultDays, this.shopId});

  factory PriceConfig.fromJson(Map<String, dynamic> json) => PriceConfig(
    id: json['id'],
    service: json['service'] ?? '',
    pricePerUnit: json['price_per_unit'] ?? 0,
    unit: json['unit'] ?? 'kg',
    defaultDays: json['default_days'] ?? 2,
    shopId: json['shop_id']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'service': service, 'price_per_unit': pricePerUnit, 'unit': unit, 
    'default_days': defaultDays, 'shop_id': shopId != null ? int.tryParse(shopId!) : null,
  };

  static List<PriceConfig> defaultPrices() => [
    // Cuci Kiloan (Paket)
    PriceConfig(service: 'Cuci 5kg',               pricePerUnit: 10000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Cuci-Kering 5kg',        pricePerUnit: 20000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Cuci-Kering-Lipat 5kg',  pricePerUnit: 25000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Cuci 8kg',               pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Cuci-Kering 8kg',        pricePerUnit: 30000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Cuci-Kering-Lipat 8kg',  pricePerUnit: 35000, unit: 'pcs', defaultDays: 2),
    // Cuci-Setrika (per kg)
    PriceConfig(service: 'Cuci-Setrika 24jam',          pricePerUnit: 9000,  unit: 'kg', defaultDays: 1),
    PriceConfig(service: 'Cuci-Setrika Express 6-8jam', pricePerUnit: 12000, unit: 'kg', defaultDays: 1),
    PriceConfig(service: 'Cuci-Setrika Kilat 3jam',     pricePerUnit: 16000, unit: 'kg', defaultDays: 1),
    PriceConfig(service: 'Setrika Saja',                pricePerUnit: 5000,  unit: 'kg', defaultDays: 1),
    PriceConfig(service: 'Setrika Saja Express',        pricePerUnit: 7000,  unit: 'kg', defaultDays: 1),
    // Selimut
    PriceConfig(service: 'Selimut Kecil',       pricePerUnit: 10000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Selimut Besar',       pricePerUnit: 15000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Selimut Tebal',       pricePerUnit: 20000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Selimut Jumbo',       pricePerUnit: 30000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Selimut Extra Jumbo', pricePerUnit: 35000, unit: 'pcs', defaultDays: 3),
    // Bed Cover
    PriceConfig(service: 'Bed Cover 4kaki',         pricePerUnit: 20000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Bed Cover 5kaki',         pricePerUnit: 25000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Bed Cover 6kaki',         pricePerUnit: 30000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Bed Cover 6kaki Berenda', pricePerUnit: 35000, unit: 'pcs', defaultDays: 4),
    // Horden
    PriceConfig(service: 'Horden', pricePerUnit: 12000, unit: 'kg', defaultDays: 3),
    // Pakaian Khusus
    PriceConfig(service: 'Kemeja/Batik',          pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Jaket Khusus',          pricePerUnit: 20000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Celana/Rok',            pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Jas',                   pricePerUnit: 20000, unit: 'pcs', defaultDays: 4),
    PriceConfig(service: 'Jas+Celana',            pricePerUnit: 30000, unit: 'set', defaultDays: 4),
    PriceConfig(service: 'Jas+Celana+Rompi',      pricePerUnit: 35000, unit: 'set', defaultDays: 4),
    PriceConfig(service: 'Selendang/Kemban',      pricePerUnit: 10000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Songket',               pricePerUnit: 25000, unit: 'pcs', defaultDays: 4),
    PriceConfig(service: 'Kebaya Pendek',         pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Kebaya Panjang',        pricePerUnit: 20000, unit: 'pcs', defaultDays: 4),
    PriceConfig(service: 'Jubah Tebal',           pricePerUnit: 30000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Jubah Tipis',           pricePerUnit: 20000, unit: 'pcs', defaultDays: 2),
    PriceConfig(service: 'Treatment Baju Luntur', pricePerUnit: 35000, unit: 'pcs', defaultDays: 5),
    PriceConfig(service: 'Gaun Anak',             pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Gaun Pendek',           pricePerUnit: 20000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Gaun Panjang',          pricePerUnit: 25000, unit: 'pcs', defaultDays: 4),
    // Boneka & Bantal
    PriceConfig(service: 'Boneka Kecil',  pricePerUnit: 15000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Boneka Sedang', pricePerUnit: 20000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Boneka Besar',  pricePerUnit: 25000, unit: 'pcs', defaultDays: 3),
    PriceConfig(service: 'Boneka Jumbo',  pricePerUnit: 30000, unit: 'pcs', defaultDays: 4),
    PriceConfig(service: 'Bantal',        pricePerUnit: 20000, unit: 'pcs', defaultDays: 2),
    // Add On
    PriceConfig(service: 'Add On: Express', pricePerUnit: 10000, unit: 'menu', defaultDays: 0),
  ];
}

// ─── OrderItem: satu baris layanan dalam pesanan ───────────────────────────
class OrderItem {
  final String service;
  final double qty;      // bisa desimal untuk kg, integer untuk pcs/set/menu
  final String unit;     // 'kg' | 'pcs' | 'set' | 'menu'
  final int pricePerUnit;
  final int subtotal;    // qty * pricePerUnit (dibulatkan)

  const OrderItem({
    required this.service,
    required this.qty,
    required this.unit,
    required this.pricePerUnit,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    service: j['service'] ?? '',
    qty: (j['qty'] ?? 0).toDouble(),
    unit: j['unit'] ?? 'kg',
    pricePerUnit: j['price_per_unit'] ?? 0,
    subtotal: j['subtotal'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'service': service,
    'qty': qty,
    'unit': unit,
    'price_per_unit': pricePerUnit,
    'subtotal': subtotal,
  };

  OrderItem copyWithQty(double newQty) => OrderItem(
    service: service,
    qty: newQty,
    unit: unit,
    pricePerUnit: pricePerUnit,
    subtotal: (pricePerUnit * newQty).round(),
  );

  /// Label ringkas untuk ditampilkan di list
  String get displayQty => unit == 'kg'
      ? '${qty % 1 == 0 ? qty.toInt() : qty} kg'
      : '${qty.toInt()} $unit';
}

class OrderData {
  String id;
  String customer;
  String phone;
  String service;
  double weight;
  int pricePerUnit;
  int price;
  String status;
  String? picId;
  String picName;
  String? picWashId;
  String? picWashName;
  String? picIronId;
  String? picIronName;
  String? picPackId;
  String? picPackName;
  String? shiftId;
  String notes;
  String estimatedDate;
  DateTime orderTime;
  DateTime? completedTime;
  DateTime? pickedUpTime;
  final String? shopId;
  String paymentStatus;
  DateTime? paymentTime;
  List<OrderItem> items; // kosong berarti order lama (single-service)

  OrderData({
    required this.id,
    required this.customer,
    this.phone = '',
    required this.service,
    required this.weight,
    this.pricePerUnit = 0,
    required this.price,
    required this.status,
    this.picId,
    this.picName = '',
    this.picWashId,
    this.picWashName,
    this.picIronId,
    this.picIronName,
    this.picPackId,
    this.picPackName,
    this.shiftId,
    this.notes = '',
    this.estimatedDate = '',
    DateTime? orderTime,
    this.completedTime,
    this.pickedUpTime,
    this.shopId,
    this.paymentStatus = 'Belum Lunas',
    this.paymentTime,
    List<OrderItem>? items,
  })  : orderTime = orderTime ?? DateTime.now(),
        items = items ?? [];

  OrderData copyWith({
    String? id, String? customer, String? phone, String? service,
    double? weight, int? pricePerUnit, int? price, String? status,
    String? picId, String? picName, 
    String? picWashId, String? picWashName,
    String? picIronId, String? picIronName,
    String? picPackId, String? picPackName,
    String? shiftId,
    String? notes, String? estimatedDate,
    DateTime? orderTime, DateTime? completedTime, DateTime? pickedUpTime,
    String? shopId,
    String? paymentStatus, DateTime? paymentTime,
    List<OrderItem>? items,
  }) => OrderData(
    id: id ?? this.id, customer: customer ?? this.customer,
    phone: phone ?? this.phone, service: service ?? this.service,
    weight: weight ?? this.weight, pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    price: price ?? this.price, status: status ?? this.status,
    picId: picId ?? this.picId, picName: picName ?? this.picName,
    picWashId: picWashId ?? this.picWashId, picWashName: picWashName ?? this.picWashName,
    picIronId: picIronId ?? this.picIronId, picIronName: picIronName ?? this.picIronName,
    picPackId: picPackId ?? this.picPackId, picPackName: picPackName ?? this.picPackName,
    shiftId: shiftId ?? this.shiftId,
    notes: notes ?? this.notes, estimatedDate: estimatedDate ?? this.estimatedDate,
    orderTime: orderTime ?? this.orderTime,
    completedTime: completedTime ?? this.completedTime,
    pickedUpTime: pickedUpTime ?? this.pickedUpTime,
    shopId: shopId ?? this.shopId,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paymentTime: paymentTime ?? this.paymentTime,
    items: items ?? List.of(this.items),
  );

  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(
    id: json['id'] ?? '',
    customer: json['customer'] ?? '',
    phone: json['phone'] ?? '',
    service: json['service'] ?? '',
    weight: (json['weight'] ?? 0).toDouble(),
    pricePerUnit: json['price_per_unit'] ?? 0,
    price: json['price'] ?? 0,
    status: json['status'] ?? 'Proses',
    picId: json['pic_id'],
    picName: json['pic_name'] ?? '',
    picWashId: json['pic_wash_id'],
    picWashName: json['pic_wash_name'],
    picIronId: json['pic_iron_id'],
    picIronName: json['pic_iron_name'],
    picPackId: json['pic_pack_id'],
    picPackName: json['pic_pack_name'],
    shiftId: json['shift_id'],
    notes: json['notes'] ?? '',
    estimatedDate: json['estimated_date'] ?? '',
    orderTime: json['order_time'] != null ? DateTime.parse(json['order_time']).toLocal() : DateTime.now(),
    completedTime: json['completed_time'] != null ? DateTime.parse(json['completed_time']).toLocal() : null,
    pickedUpTime: json['picked_up_time'] != null ? DateTime.parse(json['picked_up_time']).toLocal() : null,
    shopId: json['shop_id']?.toString(),
    paymentStatus: json['payment_status'] ?? 'Belum Lunas',
    paymentTime: json['payment_time'] != null ? DateTime.parse(json['payment_time']).toLocal() : null,
    items: json['items'] != null
        ? (json['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
        : [],
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'customer': customer,
    'phone': phone.isEmpty ? null : phone,
    'service': service, 'weight': weight,
    'price_per_unit': pricePerUnit, 'price': price, 'status': status,
    'pic_id': picId, 'pic_name': picName,
    'pic_wash_id': picWashId, 'pic_wash_name': picWashName,
    'pic_iron_id': picIronId, 'pic_iron_name': picIronName,
    'pic_pack_id': picPackId, 'pic_pack_name': picPackName,
    'shift_id': shiftId,
    'notes': notes.isEmpty ? null : notes,
    'estimated_date': estimatedDate.isEmpty ? null : estimatedDate,
    'order_time': orderTime.toUtc().toIso8601String(),
    'completed_time': completedTime?.toUtc().toIso8601String(),
    'picked_up_time': pickedUpTime?.toUtc().toIso8601String(),
    'shop_id': shopId != null ? int.tryParse(shopId!) : null,
    'payment_status': paymentStatus,
    'payment_time': paymentTime?.toUtc().toIso8601String(),
    'items': items.isEmpty ? null : items.map((e) => e.toJson()).toList(),
  };

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(orderTime);
  String get formattedPrice => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
}

class StaffData {
  String id;
  String name;
  String email;
  String username;
  String imgUrl;
  String phone;
  bool isActive;
  final String? shopId;

  StaffData({
    this.id = '',
    required this.name,
    required this.email,
    required this.username,
    this.imgUrl = '',
    this.phone = '',
    this.isActive = true,
    this.shopId,
  });

  factory StaffData.fromJson(Map<String, dynamic> json) => StaffData(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    username: json['username'] ?? '',
    imgUrl: json['img_url'] ?? 'https://i.pravatar.cc/150?u=default',
    phone: json['phone'] ?? '',
    isActive: json['is_active'] ?? true,
    shopId: json['shop_id']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'email': email, 'username': username,
    'img_url': imgUrl, 'phone': phone, 'is_active': isActive,
    'shop_id': shopId != null ? int.tryParse(shopId!) : null,
  };
}

class ShopData {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String logoUrl;
  final String receiptFooter;

  ShopData({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.logoUrl = '',
    this.receiptFooter = 'Terima kasih!',
  });

  factory ShopData.fromJson(Map<String, dynamic> json) => ShopData(
    id: json['id']?.toString() ?? '1',
    name: json['name'] ?? 'LaundryKu',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    logoUrl: json['logo_url'] ?? '',
    receiptFooter: json['receipt_footer'] ?? 'Terima kasih!',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'phone': phone,
    'logo_url': logoUrl,
    'receipt_footer': receiptFooter,
  };

  factory ShopData.defaultShop() => ShopData(
    id: '1',
    name: 'LaundryKu',
    address: 'Jl. Contoh No. 123',
    phone: '08123456789',
    receiptFooter: 'Terima kasih telah menggunakan jasa kami!',
  );
}


class AppState {
  final List<OrderData> orders;
  final List<StaffData> staffList;
  List<PriceConfig> prices;
  StaffData? currentUser;
  ShopData currentShop;
  List<ShopData> allShops;

  AppState({
    required this.orders, 
    required this.staffList, 
    List<PriceConfig>? prices, 
    this.currentUser, 
    ShopData? shop,
    List<ShopData>? allShops,
  }) : prices = prices ?? PriceConfig.defaultPrices(),
       currentShop = shop ?? ShopData.defaultShop(),
       allShops = allShops ?? [ShopData.defaultShop()];

  List<OrderData> get activeOrders => orders.where((o) => o.status == 'Proses').toList();
  List<OrderData> get completedOrders => orders.where((o) => o.status == 'Selesai').toList();
  List<OrderData> get pickedUpOrders => orders.where((o) => o.status == 'Sudah Diambil').toList();

  int get totalProses => orders.where((o) => o.status == 'Proses').length;
  int get totalSelesai => orders.where((o) => o.status == 'Selesai').length;
  int get totalSudahDiambil => orders.where((o) => o.status == 'Sudah Diambil').length;
  int get totalStaff => staffList.length;
  int get activeStaff => staffList.where((s) => s.isActive).length;

  List<OrderData> get recentOrders {
    final sorted = List<OrderData>.from(orders);
    sorted.sort((a, b) => b.orderTime.compareTo(a.orderTime));
    return sorted.take(10).toList();
  }

  int incomeForPeriod(DateTime start, DateTime end) =>
      orders.where((o) => o.status == 'Sudah Diambil' && o.pickedUpTime != null && 
          !o.pickedUpTime!.isBefore(start) && o.pickedUpTime!.isBefore(end))
          .fold(0, (s, o) => s + o.price);

  int ordersForPeriod(DateTime start, DateTime end) =>
      orders.where((o) => o.status == 'Sudah Diambil' && o.pickedUpTime != null &&
          !o.pickedUpTime!.isBefore(start) && o.pickedUpTime!.isBefore(end)).length;

  /// Total nilai kain yang masuk (semua order hari ini by orderTime, tanpa filter status)
  int fabricReceivedForPeriod(DateTime start, DateTime end) =>
      orders.where((o) =>
          !o.orderTime.isBefore(start) && o.orderTime.isBefore(end))
          .fold(0, (s, o) => s + o.price);

  /// Jumlah pesanan masuk di periode
  int ordersReceivedForPeriod(DateTime start, DateTime end) =>
      orders.where((o) =>
          !o.orderTime.isBefore(start) && o.orderTime.isBefore(end)).length;

  PriceConfig? getPriceConfig(String service) {
    try { return prices.firstWhere((p) => p.service == service); }
    catch (_) { return null; }
  }
}

class CashierShift {
  final String id;
  final String staffId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double? openingCash;
  final double? closingPhysicalCash;
  final double? totalRevenue;
  final String? notes;

  CashierShift({
    required this.id,
    required this.staffId,
    required this.openedAt,
    this.closedAt,
    this.openingCash,
    this.closingPhysicalCash,
    this.totalRevenue,
    this.notes,
  });

  factory CashierShift.fromJson(Map<String, dynamic> json) => CashierShift(
    id: json['id'],
    staffId: json['staff_id'],
    openedAt: DateTime.parse(json['opened_at']).toLocal(),
    closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']).toLocal() : null,
    openingCash: (json['opening_cash'] ?? 0).toDouble(),
    closingPhysicalCash: json['closing_physical_cash'] != null ? (json['closing_physical_cash'] ?? 0).toDouble() : null,
    totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    notes: json['notes'],
  );

  Map<String, dynamic> toMap() => {
    'staff_id': staffId,
    'opened_at': openedAt.toUtc().toIso8601String(),
    'closed_at': closedAt?.toUtc().toIso8601String(),
    'opening_cash': openingCash,
    'closing_physical_cash': closingPhysicalCash,
    'total_revenue': totalRevenue,
    'notes': notes,
  };
}

enum AuditActionType { void_order, price_change, delete_order, manual_status_change }

class AuditLog {
  final String id;
  final AuditActionType action;
  final String? orderId;
  final String staffId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? reason;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    this.orderId,
    required this.staffId,
    this.oldData,
    this.newData,
    this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'],
    action: AuditActionType.values.firstWhere((e) => e.name == json['action'],
        orElse: () => AuditActionType.manual_status_change),
    orderId: json['order_id'],
    staffId: json['staff_id'],
    oldData: json['old_data'],
    newData: json['new_data'],
    reason: json['reason'],
    createdAt: DateTime.parse(json['created_at']).toLocal(),
  );

  Map<String, dynamic> toMap() => {
    'action': action.name,
    'order_id': orderId,
    'staff_id': staffId,
    'old_data': oldData,
    'new_data': newData,
    'reason': reason,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
