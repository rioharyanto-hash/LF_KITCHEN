import 'package:flutter_test/flutter_test.dart';
import 'package:lf_kitchen/features/orders/domain/entities/order.dart';
import 'package:lf_kitchen/features/orders/data/models/order_model.dart';

void main() {
  group('OrderModel', () {
    final sampleJson = {
      'id': 'order-1',
      'customer_id': 'cust-1',
      'customer_name': null,
      'customer_phone': null,
      'customers': {
        'name': 'John Doe',
        'phone': '081234',
        'address': 'Jl. Test',
      },
      'order_date': '2026-01-15T00:00:00.000Z',
      'order_type': 'PO',
      'status': 'CONFIRMED',
      'total_amount': 500000,
      'dp_amount': 200000,
      'payment_status': 'PARTIAL',
      'delivery_date': '2026-01-20T00:00:00.000Z',
      'notes': 'Special order',
      'created_at': '2026-01-15T10:00:00.000Z',
      'updated_at': null,
      'receipt_number': 'INV-001',
      'shipping_cost': 25000,
      'payment_method': 'Transfer',
      'order_items': [
        {
          'id': 'item-1',
          'order_id': 'order-1',
          'product_id': 'prod-1',
          'product_name': null,
          'products': {'name': 'Kue Lapis'},
          'quantity': 5,
          'unit_price': 100000,
          'subtotal': 500000,
          'produced_qty': 3,
          'created_at': '2026-01-15T10:00:00.000Z',
        },
      ],
    };

    group('fromJson', () {
      test('parses all fields correctly', () {
        final model = OrderModel.fromJson(sampleJson);

        expect(model.id, 'order-1');
        expect(model.customerId, 'cust-1');
        expect(model.customerName, 'John Doe'); // from customers join
        expect(model.customerPhone, '081234');
        expect(model.customerAddress, 'Jl. Test');
        expect(model.orderType, OrderType.po);
        expect(model.status, OrderStatus.confirmed);
        expect(model.totalAmount, 500000);
        expect(model.dpAmount, 200000);
        expect(model.paymentStatus, PaymentStatus.partial);
        expect(model.receiptNumber, 'INV-001');
        expect(model.shippingCost, 25000);
        expect(model.paymentMethod, 'Transfer');
        expect(model.items, isNotNull);
        expect(model.items!.length, 1);
      });

      test('handles null optional fields', () {
        final minimalJson = {
          'id': 'order-2',
          'order_date': '2026-01-15T00:00:00.000Z',
          'order_type': 'DIRECT',
          'status': 'DRAFT',
          'total_amount': 100000,
          'payment_status': 'UNPAID',
          'created_at': '2026-01-15T10:00:00.000Z',
        };

        final model = OrderModel.fromJson(minimalJson);
        expect(model.id, 'order-2');
        expect(model.customerId, isNull);
        expect(model.customerName, isNull);
        expect(model.items, isNull);
        expect(model.dpAmount, 0);
        expect(model.shippingCost, 0);
      });

      test('defaults to correct enum values on unknown strings', () {
        final badEnumJson = {
          'id': 'order-3',
          'order_date': '2026-01-15T00:00:00.000Z',
          'order_type': 'UNKNOWN_TYPE',
          'status': 'UNKNOWN_STATUS',
          'total_amount': 0,
          'payment_status': 'UNKNOWN_PAYMENT',
          'created_at': '2026-01-15T00:00:00.000Z',
        };

        final model = OrderModel.fromJson(badEnumJson);
        expect(model.orderType, OrderType.direct);
        expect(model.status, OrderStatus.draft);
        expect(model.paymentStatus, PaymentStatus.unpaid);
      });
    });

    group('toInsertJson', () {
      test('serializes correctly for Supabase insert', () {
        final model = OrderModel.fromJson(sampleJson);
        final json = model.toInsertJson();

        expect(json['customer_id'], 'cust-1');
        expect(json['order_type'], 'PO');
        expect(json['status'], 'CONFIRMED');
        expect(json['total_amount'], 500000);
        expect(json['dp_amount'], 200000);
        expect(json['payment_status'], 'PARTIAL');
        expect(json['shipping_cost'], 25000);
        expect(json['payment_method'], 'Transfer');
        // Should NOT contain 'id' or 'created_at'
        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('fromEntity', () {
      test('converts Order entity to OrderModel', () {
        final entity = Order(
          id: 'e-1',
          orderDate: DateTime(2026, 1, 1),
          orderType: OrderType.direct,
          status: OrderStatus.draft,
          totalAmount: 100000,
          paymentStatus: PaymentStatus.unpaid,
          createdAt: DateTime(2026, 1, 1),
        );

        final model = OrderModel.fromEntity(entity);
        expect(model.id, 'e-1');
        expect(model.orderType, OrderType.direct);
        expect(model.totalAmount, 100000);
      });
    });
  });

  group('OrderItemModel', () {
    final itemJson = {
      'id': 'item-1',
      'order_id': 'order-1',
      'product_id': 'prod-1',
      'product_name': null,
      'products': {'name': 'Kue Lapis'},
      'quantity': 5,
      'unit_price': 100000,
      'subtotal': 500000,
      'produced_qty': 3,
      'created_at': '2026-01-15T10:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final model = OrderItemModel.fromJson(itemJson);

      expect(model.id, 'item-1');
      expect(model.orderId, 'order-1');
      expect(model.productId, 'prod-1');
      expect(model.productName, 'Kue Lapis'); // from products join
      expect(model.quantity, 5);
      expect(model.unitPrice, 100000);
      expect(model.subtotal, 500000);
      expect(model.producedQty, 3);
    });

    test('toInsertJson includes product_id and product_name when present', () {
      final model = OrderItemModel.fromJson(itemJson);
      final json = model.toInsertJson();

      expect(json['order_id'], 'order-1');
      expect(json['product_id'], 'prod-1');
      expect(json['quantity'], 5);
      expect(json['unit_price'], 100000);
      expect(json['subtotal'], 500000);
      // Should NOT contain 'id'
      expect(json.containsKey('id'), false);
    });

    test('toInsertJson excludes product_id when null', () {
      final noProductJson = {
        'id': 'item-2',
        'order_id': 'order-1',
        'product_id': null,
        'product_name': 'Snack Box',
        'quantity': 1,
        'unit_price': 50000,
        'subtotal': 50000,
      };

      final model = OrderItemModel.fromJson(noProductJson);
      final json = model.toInsertJson();
      expect(json.containsKey('product_id'), false);
      expect(json['product_name'], 'Snack Box');
    });

    test('fromEntity converts OrderItem to OrderItemModel', () {
      const entity = OrderItem(
        id: 'e-item-1',
        orderId: 'e-order-1',
        productId: 'p1',
        productName: 'Test',
        quantity: 3,
        unitPrice: 10000,
        subtotal: 30000,
      );

      final model = OrderItemModel.fromEntity(entity);
      expect(model.id, 'e-item-1');
      expect(model.orderId, 'e-order-1');
      expect(model.quantity, 3);
    });
  });
}
