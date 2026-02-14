import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lf_kitchen/core/utils/result.dart';
import 'package:lf_kitchen/features/orders/domain/entities/order.dart';
import 'package:lf_kitchen/features/orders/domain/repositories/i_order_repository.dart';
import 'package:lf_kitchen/features/orders/data/providers/order_providers.dart';

class MockOrderRepository extends Mock implements IOrderRepository {}

void main() {
  late MockOrderRepository mockRepository;
  late OrderFormNotifier notifier;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      Order(
        id: '',
        orderDate: DateTime(2026),
        orderType: OrderType.direct,
        status: OrderStatus.draft,
        totalAmount: 0,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(<OrderItem>[]);
  });

  setUp(() {
    mockRepository = MockOrderRepository();
    notifier = OrderFormNotifier(mockRepository);
  });

  group('OrderFormNotifier', () {
    group('addItem', () {
      test('adds new item to the list', () {
        const item = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 2,
          unitPrice: 100000,
          subtotal: 200000,
        );

        notifier.addItem(item);
        expect(notifier.state.items.length, 1);
        expect(notifier.state.items.first.productName, 'Kue Lapis');
      });

      test('merges quantity when adding existing product', () {
        const item1 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 2,
          unitPrice: 100000,
          subtotal: 200000,
        );

        const item2 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 3,
          unitPrice: 100000,
          subtotal: 300000,
        );

        notifier.addItem(item1);
        notifier.addItem(item2);

        expect(notifier.state.items.length, 1);
        expect(notifier.state.items.first.quantity, 5); // 2 + 3
        expect(notifier.state.items.first.subtotal, 500000); // 5 * 100000
      });

      test('adds separate item for different product', () {
        const item1 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 1,
          unitPrice: 100000,
          subtotal: 100000,
        );

        const item2 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-2',
          productName: 'Brownies',
          quantity: 1,
          unitPrice: 80000,
          subtotal: 80000,
        );

        notifier.addItem(item1);
        notifier.addItem(item2);
        expect(notifier.state.items.length, 2);
      });
    });

    group('updateItemQuantity', () {
      test('updates quantity and subtotal', () {
        const item = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 2,
          unitPrice: 100000,
          subtotal: 200000,
        );

        notifier.addItem(item);
        notifier.updateItemQuantity(0, 5);

        expect(notifier.state.items.first.quantity, 5);
        expect(notifier.state.items.first.subtotal, 500000);
      });

      test('ignores invalid index', () {
        notifier.updateItemQuantity(-1, 5);
        notifier.updateItemQuantity(99, 5);
        // Should not throw
      });
    });

    group('removeItem', () {
      test('removes item at index', () {
        const item = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 1,
          unitPrice: 100000,
          subtotal: 100000,
        );

        notifier.addItem(item);
        expect(notifier.state.items.length, 1);

        notifier.removeItem(0);
        expect(notifier.state.items.length, 0);
      });

      test('ignores invalid index', () {
        notifier.removeItem(-1);
        notifier.removeItem(0);
        // Should not throw
      });
    });

    group('totalAmount', () {
      test('computes total from all items', () {
        const item1 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Kue Lapis',
          quantity: 2,
          unitPrice: 100000,
          subtotal: 200000,
        );

        const item2 = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-2',
          productName: 'Brownies',
          quantity: 1,
          unitPrice: 80000,
          subtotal: 80000,
        );

        notifier.addItem(item1);
        notifier.addItem(item2);

        expect(notifier.state.totalAmount, 280000);
      });

      test('returns 0 when no items', () {
        expect(notifier.state.totalAmount, 0);
      });
    });

    group('createOrder', () {
      test('creates order and sets success state', () async {
        final createdOrder = Order(
          id: 'new-order-1',
          orderDate: DateTime(2026, 1, 15),
          orderType: OrderType.po,
          status: OrderStatus.draft,
          totalAmount: 200000,
          paymentStatus: PaymentStatus.unpaid,
          createdAt: DateTime(2026, 1, 15),
        );

        when(
          () => mockRepository.create(any(), any()),
        ).thenAnswer((_) async => Success(createdOrder));

        // Add an item first
        const item = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Test',
          quantity: 2,
          unitPrice: 100000,
          subtotal: 200000,
        );
        notifier.addItem(item);

        final result = await notifier.createOrder(
          customerId: 'cust-1',
          orderType: OrderType.po,
          deliveryDate: DateTime(2026, 1, 20),
          dpAmount: 0,
          notes: 'Test notes',
        );

        expect(result.isSuccess, true);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.order?.id, 'new-order-1');
      });

      test('sets error state on failure', () async {
        when(
          () => mockRepository.create(any(), any()),
        ).thenAnswer((_) async => const Failure('Database error'));

        final result = await notifier.createOrder(
          customerId: null,
          orderType: OrderType.direct,
          deliveryDate: null,
          dpAmount: 0,
          notes: null,
        );

        expect(result.isFailure, true);
        expect(notifier.state.error, 'Database error');
        expect(notifier.state.isLoading, false);
      });
    });

    group('reset', () {
      test('clears all state', () {
        const item = OrderItem(
          id: '',
          orderId: '',
          productId: 'prod-1',
          productName: 'Test',
          quantity: 1,
          unitPrice: 100000,
          subtotal: 100000,
        );

        notifier.addItem(item);
        expect(notifier.state.items.length, 1);

        notifier.reset();
        expect(notifier.state.items.length, 0);
        expect(notifier.state.order, isNull);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, isNull);
      });
    });
  });
}
