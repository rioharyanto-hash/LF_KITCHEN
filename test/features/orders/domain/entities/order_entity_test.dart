import 'package:flutter_test/flutter_test.dart';
import 'package:lf_kitchen/features/orders/domain/entities/order.dart';

void main() {
  group('Order Entity', () {
    late Order order;

    setUp(() {
      order = Order(
        id: 'order-1',
        customerId: 'cust-1',
        customerName: 'John Doe',
        customerPhone: '08123456789',
        orderDate: DateTime(2026, 1, 15),
        orderType: OrderType.po,
        status: OrderStatus.confirmed,
        totalAmount: 500000,
        dpAmount: 200000,
        paymentStatus: PaymentStatus.partial,
        deliveryDate: DateTime(2026, 1, 20),
        notes: 'Special cake',
        createdAt: DateTime(2026, 1, 15),
        shippingCost: 25000,
        paymentMethod: 'Transfer',
        items: const [
          OrderItem(
            id: 'item-1',
            orderId: 'order-1',
            productId: 'prod-1',
            productName: 'Kue Lapis',
            quantity: 5,
            unitPrice: 100000,
            subtotal: 500000,
            producedQty: 3,
          ),
        ],
      );
    });

    group('computed properties', () {
      test('grandTotal = totalAmount + shippingCost', () {
        expect(order.grandTotal, 525000);
      });

      test('remainingPayment = grandTotal - dpAmount', () {
        expect(order.remainingPayment, 325000);
      });

      test('isPaid returns true when paymentStatus is paid', () {
        expect(order.isPaid, false);
        final paidOrder = order.copyWith(paymentStatus: PaymentStatus.paid);
        expect(paidOrder.isPaid, true);
      });

      test('statusLabel returns correct Indonesian label', () {
        expect(order.statusLabel, 'Dikonfirmasi');

        final draftOrder = order.copyWith(status: OrderStatus.draft);
        expect(draftOrder.statusLabel, 'Draft');

        final processingOrder = order.copyWith(status: OrderStatus.processing);
        expect(processingOrder.statusLabel, 'Dalam Produksi');

        final readyOrder = order.copyWith(status: OrderStatus.ready);
        expect(readyOrder.statusLabel, 'Siap Diambil');

        final completedOrder = order.copyWith(status: OrderStatus.completed);
        expect(completedOrder.statusLabel, 'Selesai');

        final cancelledOrder = order.copyWith(status: OrderStatus.cancelled);
        expect(cancelledOrder.statusLabel, 'Dibatalkan');
      });

      test('paymentLabel returns correct Indonesian label', () {
        expect(order.paymentLabel, 'DP');

        final unpaidOrder = order.copyWith(paymentStatus: PaymentStatus.unpaid);
        expect(unpaidOrder.paymentLabel, 'Belum Bayar');

        final paidOrder = order.copyWith(paymentStatus: PaymentStatus.paid);
        expect(paidOrder.paymentLabel, 'Lunas');
      });
    });

    group('copyWith', () {
      test('returns new instance with updated fields', () {
        final updated = order.copyWith(
          customerName: 'Jane Doe',
          totalAmount: 750000,
        );
        expect(updated.customerName, 'Jane Doe');
        expect(updated.totalAmount, 750000);
        // Unchanged fields
        expect(updated.id, 'order-1');
        expect(updated.customerId, 'cust-1');
      });

      test('returns identical copy when no fields specified', () {
        final copy = order.copyWith();
        expect(copy, equals(order));
      });
    });

    group('Equatable equality', () {
      test('two orders with same properties are equal', () {
        final order2 = order.copyWith();
        expect(order, equals(order2));
      });

      test('two orders with different ids are not equal', () {
        final order2 = order.copyWith(id: 'order-2');
        expect(order, isNot(equals(order2)));
      });
    });
  });

  group('OrderItem Entity', () {
    late OrderItem item;

    setUp(() {
      item = const OrderItem(
        id: 'item-1',
        orderId: 'order-1',
        productId: 'prod-1',
        productName: 'Kue Lapis',
        quantity: 10,
        unitPrice: 50000,
        subtotal: 500000,
        producedQty: 10,
      );
    });

    test('isProducedComplete returns true when producedQty >= quantity', () {
      expect(item.isProducedComplete, true);

      final partial = item.copyWith(producedQty: 5);
      expect(partial.isProducedComplete, false);
    });

    test('remainingToProduce returns correct count', () {
      expect(item.remainingToProduce, 0);

      final partial = item.copyWith(producedQty: 3);
      expect(partial.remainingToProduce, 7);
    });

    test('copyWith returns updated OrderItem', () {
      final updated = item.copyWith(quantity: 20, subtotal: 1000000);
      expect(updated.quantity, 20);
      expect(updated.subtotal, 1000000);
      expect(updated.productName, 'Kue Lapis'); // unchanged
    });

    test('Equatable equality works', () {
      final item2 = item.copyWith();
      expect(item, equals(item2));
    });
  });
}
