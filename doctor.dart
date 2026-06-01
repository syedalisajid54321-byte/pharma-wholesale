// lib/models/doctor.dart
class Doctor {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double balance; // outstanding balance (positive = owes us)
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.balance = 0.0,
    required this.createdAt,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
