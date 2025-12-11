part of 'devices_cubit.dart';

/// Devices state
class DevicesState extends Equatable {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  const DevicesState({
    required this.devices,
    this.isLoading = false,
    this.error,
  });

  const DevicesState.initial()
      : devices = const [],
        isLoading = false,
        error = null;

  const DevicesState.loading()
      : devices = const [],
        isLoading = true,
        error = null;

  const DevicesState.loaded(List<Device> this.devices)
      : isLoading = false,
        error = null;

  const DevicesState.error(String this.error)
      : devices = const [],
        isLoading = false;

  @override
  List<Object?> get props => [devices, isLoading, error];
}

