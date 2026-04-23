import 'package:intl/intl.dart';

// ==================== ORDER MODEL ====================
class OrderData {
  String id;
  String customer;
  String service;
  double weight;
  int price;
  String status;
  String pic;
  String date;

  OrderData({
    required this.id,
    required this.customer,
    required this.service,
    required this.weight,
    required this.price,
    required this.status,
    required this.pic,
    required this.date,
  });

  OrderData copyWith({
    String? id,
    String? customer,
    String? service,
    double? weight,
    int? price,
    String? status,
    String? pic,
    String? date,
  }) {
    return OrderData(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      service: service ?? this.service,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      status: status ?? this.status,
      pic: pic ?? this.pic,
      date: date ?? this.date,
    );
  }

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'] ?? '',
      customer: json['customer'] ?? '',
      service: json['service'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      price: json['price'] ?? 0,
      status: json['status'] ?? '',
      pic: json['pic'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer': customer,
      'service': service,
      'weight': weight,
      'price': price,
      'status': status,
      'pic': pic,
      'date': date,
    };
  }
}

// ==================== STAFF MODEL ====================
class StaffData {
  String name;
  String email;
  String username;
  String imgUrl;
  bool isActive;

  StaffData({
    required this.name,
    required this.email,
    required this.username,
    required this.imgUrl,
    this.isActive = true,
  });

  factory StaffData.fromJson(Map<String, dynamic> json) {
    return StaffData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      imgUrl: json['img_url'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'username': username,
      'img_url': imgUrl,
      'is_active': isActive,
    };
  }
}

// ==================== SHARED APP STATE ====================
class AppState {
  final List<OrderData> orders;
  final List<StaffData> staffList;

  AppState({required this.orders, required this.staffList});

  // ---- Order Computed Getters ----

  double get todayIncome {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return orders
        .where((o) => o.date == today)
        .fold(0.0, (sum, o) => sum + o.price);
  }

  int get activeOrders {
    return orders.where((o) => o.status != 'Selesai').length;
  }

  int get backlog {
    return orders.where((o) => o.status == 'Belum Bayar').length;
  }

  List<String> get _uniqueCustomers => orders.map((o) => o.customer).toSet().toList();

  int get totalCustomers => _uniqueCustomers.length;

  Map<String, int> get statusDistribution {
    final map = <String, int>{};
    for (var o in orders) {
      if (o.status != 'Selesai') {
        map[o.status] = (map[o.status] ?? 0) + 1;
      }
    }
    return map;
  }

  double get totalIncome => orders.fold(0.0, (sum, o) => sum + o.price);

  List<OrderData> get recentOrders {
    final sorted = List<OrderData>.from(orders);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  // ---- Staff Computed Getters ----
  int get totalStaff => staffList.length;
  int get activeStaff => staffList.where((s) => s.isActive).length;

  // ---- Default Data ----
  static AppState createDefault() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    final twoDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 2)));
    final threeDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 3)));

    return AppState(
      orders: [
        OrderData(id: 'LF-98231-X', customer: 'Budi Santoso', service: 'Express', weight: 3.5, price: 52500, status: 'Proses', pic: 'Sarah Wilson', date: today),
        OrderData(id: 'LF-77210-B', customer: 'Anita Wijaya', service: 'Regular', weight: 5.0, price: 50000, status: 'Selesai', pic: 'Marcus Chen', date: yesterday),
        OrderData(id: 'LF-55421-Z', customer: 'Rian Pratama', service: 'Dry Clean', weight: 2.0, price: 60000, status: 'Selesai', pic: 'Sarah Wilson', date: yesterday),
        OrderData(id: 'LF-44102-A', customer: 'Dewi Lestari', service: 'Express', weight: 4.0, price: 60000, status: 'Belum Bayar', pic: 'David Miller', date: twoDaysAgo),
        OrderData(id: 'LF-33891-C', customer: 'Ahmad Fauzi', service: 'Regular', weight: 7.5, price: 75000, status: 'Proses', pic: 'Elena Rodriguez', date: twoDaysAgo),
        OrderData(id: 'LF-22780-D', customer: 'Siti Rahayu', service: 'Premium', weight: 3.0, price: 90000, status: 'Selesai', pic: 'Marcus Chen', date: threeDaysAgo),
        OrderData(id: 'LF-11234-E', customer: 'Hani Puspita', service: 'Kiloan', weight: 6.0, price: 42000, status: 'Cuci', pic: 'Sarah Wilson', date: today),
        OrderData(id: 'LF-88432-F', customer: 'Rudi Hermawan', service: 'Express', weight: 2.5, price: 37500, status: 'Siap Ambil', pic: 'David Miller', date: today),
      ],
      staffList: [
        StaffData(name: 'Sarah Wilson', email: 'sarah.w@laundryflow.com', username: 'sarah_w', imgUrl: 'https://i.pravatar.cc/150?u=s5', isActive: true),
        StaffData(name: 'Marcus Chen', email: 'marcus.c@laundryflow.com', username: 'marcus_c', imgUrl: 'https://i.pravatar.cc/150?u=s6', isActive: true),
        StaffData(name: 'David Miller', email: 'd.miller@laundryflow.com', username: 'd_miller', imgUrl: 'https://i.pravatar.cc/150?u=s7', isActive: true),
        StaffData(name: 'Elena Rodriguez', email: 'elena.r@laundryflow.com', username: 'elena_r', imgUrl: 'https://i.pravatar.cc/150?u=s8', isActive: false),
      ],
    );
  }
}
