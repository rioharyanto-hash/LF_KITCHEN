import 'package:flutter/foundation.dart';

/// Model untuk Supplier (Pemasok Bahan)
@immutable
class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.contactPerson,
    required this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      contactPerson: json['contact_person'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? contactPerson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
