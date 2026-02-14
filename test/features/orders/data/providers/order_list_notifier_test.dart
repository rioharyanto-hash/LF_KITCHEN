import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lf_kitchen/core/utils/async_state.dart';
import 'package:lf_kitchen/core/utils/result.dart';
import 'package:lf_kitchen/features/orders/domain/entities/order.dart';
import 'package:lf_kitchen/features/orders/domain/repositories/i_order_repository.dart';
import 'package:lf_kitchen/features/orders/data/providers/order_providers.dart';

class MockOrderRepository extends Mock implements IOrderRepository {}

/// Helper to create a sample Order for testing
Order _createOrder({
  String id = 'order-1',
  OrderStatus status = OrderStatus.draft,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) {
  return Order(
    id: id,
    orderDate: DateTime(2026, 1, 15),
    orderType: OrderType.po,
    status: status,
    totalAmount: 500000,
    paymentStatus: paymentStatus,
    createdAt: DateTime(2026, 1, 15),
  );
}

void main() {
  late MockOrderRepository mockRepository;
  late OrderListNotifier notifier;

  setUp(() {
    mockRepository = MockOrderRepository();
    notifier = OrderListNotifier(mockRepository);
  });

  group('OrderListNotifier', () {
    group('loadOrders', () {
      test('sets success state with data on successful load', () async {
        final orders = [_createOrder(id: '1'), _createOrder(id: '2')];

        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success(orders));

        await notifier.loadOrders();

        expect(notifier.state.isSuccess, true);
        expect(notifier.state.data!.length, 2);
      });

      test('sets error state on failure', () async {
        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => const Failure('Network error'));

        await notifier.loadOrders();

        expect(notifier.state.isError, true);
        expect(notifier.state.errorMessage, 'Network error');
      });

      test('passes filter parameters correctly', () async {
        when(
          () => mockRepository.getAll(
            type: OrderType.po,
            status: OrderStatus.confirmed,
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => const Success([]));

        await notifier.loadOrders(
          type: OrderType.po,
          status: OrderStatus.confirmed,
        );

        verify(
          () => mockRepository.getAll(
            type: OrderType.po,
            status: OrderStatus.confirmed,
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      });
    });

    group('loadMore', () {
      test('appends new data to existing list', () async {
        // First load
        final page1 = List.generate(20, (i) => _createOrder(id: 'p1-$i'));
        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success(page1));

        await notifier.loadOrders();
        expect(notifier.state.data!.length, 20);

        // Load more
        final page2 = [_createOrder(id: 'p2-1'), _createOrder(id: 'p2-2')];
        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: 2,
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success(page2));

        await notifier.loadMore();
        expect(notifier.state.data!.length, 22); // 20 + 2
      });

      test('does nothing when no more data available', () async {
        // Load less than page size (signals no more data)
        final smallPage = [_createOrder(id: '1')];
        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success(smallPage));

        await notifier.loadOrders();

        // Reset interactions
        clearInteractions(mockRepository);

        await notifier.loadMore();
        // Should not call repository again
        verifyNever(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        );
      });
    });

    group('refresh', () {
      test('resets pagination and reloads data', () async {
        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => Success([_createOrder()]));

        await notifier.loadOrders(type: OrderType.po);
        await notifier.refresh();

        // Should re-fetch with page 1 and same filters
        verify(
          () => mockRepository.getAll(
            type: OrderType.po,
            status: null,
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).called(2); // initial load + refresh
      });
    });

    group('updateStatus', () {
      test('calls repository and refreshes on success', () async {
        when(
          () => mockRepository.updateStatus('order-1', OrderStatus.confirmed),
        ).thenAnswer((_) async => const Success(null));

        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final result = await notifier.updateStatus(
          'order-1',
          OrderStatus.confirmed,
        );

        expect(result, true);
        verify(
          () => mockRepository.updateStatus('order-1', OrderStatus.confirmed),
        ).called(1);
      });

      test('returns false on failure', () async {
        when(
          () => mockRepository.updateStatus('order-1', OrderStatus.confirmed),
        ).thenAnswer((_) async => const Failure('Error'));

        final result = await notifier.updateStatus(
          'order-1',
          OrderStatus.confirmed,
        );
        expect(result, false);
      });
    });

    group('deleteOrder', () {
      test('calls repository and refreshes on success', () async {
        when(
          () => mockRepository.delete('order-1'),
        ).thenAnswer((_) async => const Success(null));

        when(
          () => mockRepository.getAll(
            type: any(named: 'type'),
            status: any(named: 'status'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final result = await notifier.deleteOrder('order-1');
        expect(result, true);
      });
    });
  });
}
