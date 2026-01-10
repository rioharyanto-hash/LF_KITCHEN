/// Generic Async State untuk menampilkan Loading, Error, dan Data
/// dengan Visual Warning yang jelas
enum AsyncStatus { initial, loading, success, error }

class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final String? errorMessage;
  final String? errorCode;

  const AsyncState._({
    required this.status,
    this.data,
    this.errorMessage,
    this.errorCode,
  });

  /// Initial state - belum ada data
  const AsyncState.initial()
    : status = AsyncStatus.initial,
      data = null,
      errorMessage = null,
      errorCode = null;

  /// Loading state - sedang mengambil data
  const AsyncState.loading()
    : status = AsyncStatus.loading,
      data = null,
      errorMessage = null,
      errorCode = null;

  /// Success state - data berhasil diambil
  AsyncState.success(T this.data)
    : status = AsyncStatus.success,
      errorMessage = null,
      errorCode = null;

  /// Error state - terjadi kesalahan
  const AsyncState.error(this.errorMessage, {this.errorCode})
    : status = AsyncStatus.error,
      data = null;

  /// Loading state tapi tetap simpan data sebelumnya (untuk refresh)
  AsyncState<T> copyWithLoading() => AsyncState._(
    status: AsyncStatus.loading,
    data: data,
    errorMessage: null,
    errorCode: null,
  );

  bool get isInitial => status == AsyncStatus.initial;
  bool get isLoading => status == AsyncStatus.loading;
  bool get isSuccess => status == AsyncStatus.success;
  bool get isError => status == AsyncStatus.error;
  bool get hasData => data != null;

  /// Pattern matching untuk UI
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message, String? code) error,
  }) {
    switch (status) {
      case AsyncStatus.initial:
        return initial();
      case AsyncStatus.loading:
        return loading();
      case AsyncStatus.success:
        return success(data as T);
      case AsyncStatus.error:
        return error(errorMessage ?? 'Unknown error', errorCode);
    }
  }

  /// Pattern matching dengan loading yang menampilkan data lama
  R whenWithData<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) success,
    required R Function(String message, String? code) error,
  }) {
    switch (status) {
      case AsyncStatus.initial:
        return initial();
      case AsyncStatus.loading:
        return loading(data);
      case AsyncStatus.success:
        return success(data as T);
      case AsyncStatus.error:
        return error(errorMessage ?? 'Unknown error', errorCode);
    }
  }
}
