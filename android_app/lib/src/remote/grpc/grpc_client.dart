import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grpc/grpc.dart';

import '../../generated/hello.pbgrpc.dart'; // Ensure this path is correct

/// A singleton gRPC client that manages a single channel and provides access
/// to gRPC services. It includes a robust reconnection strategy with
/// exponential backoff and jitter.
class GrpcClient {
  static GrpcClient? _instance;

  factory GrpcClient() {
    // Standard Singleton access point
    _instance ??= GrpcClient._internal(
      host: dotenv.env['GRPC_HOST']!,
      port: int.parse(dotenv.env['GRPC_PORT']!),
      maxRetries: int.parse(dotenv.env['GRPC_MAX_RETRIES'] ?? '5'),
    );
    return _instance!;
  }

  final String _host;
  final int _port;
  final int _maxRetries;

  ClientChannel? _channel;
  HelloGrpcClient? _helloClient;
  SumServiceClient? _sumClient;

  // Use a Completer to manage the channel's ready state
  Completer<void>? _initializeCompleter;
  bool _isShutdown = false;

  GrpcClient._internal({
    required String host,
    required int port,
    required int maxRetries,
  })  : _host = host,
        _port = port,
        _maxRetries = maxRetries;

  // Accessors are now asynchronous (Future<T>)
  Future<HelloGrpcClient> get helloClient async => await _getClientAsync(
      () => _helloClient!, (channel) => HelloGrpcClient(channel));

  Future<SumServiceClient> get sumClient async => await _getClientAsync(
      () => _sumClient!, (channel) => SumServiceClient(channel));

  /// Internal method to ensure the channel is initialized before returning a client.
  Future<T> _getClientAsync<T>(
      T Function() getter, T Function(ClientChannel) creator) async {
    // If the channel is null, we must wait for it to be initialized.
    if (_channel == null) {
      // Wait for the initialization to complete
      await _initializeChannel();
    }

    // Now that _channel is ready, return the client
    return getter();
  }

  /// Establishes the gRPC channel with retries and backoff.
  Future<void> _initializeChannel() async {
    // If a channel already exists or we are mid-initialization, return the existing future.
    if (_channel != null) return;

    // Check if initialization is already underway
    if (_initializeCompleter?.isCompleted == false) {
      return _initializeCompleter!.future;
    }

    _initializeCompleter = Completer<void>();
    int retryAttempt = 0;

    while (_channel == null && !_isShutdown && retryAttempt < _maxRetries) {
      try {
        print('Attempting to establish gRPC channel: $_host:$_port');

        // --- CHANNEL SETUP ---
        _channel = ClientChannel(
          _host,
          port: _port,
          options: const ChannelOptions(
            credentials: ChannelCredentials.insecure(),
            idleTimeout: Duration(seconds: 30),
          ),
        );

        _helloClient = HelloGrpcClient(_channel!);
        _sumClient = SumServiceClient(_channel!);

        // Optional: Perform an actual connection check
        // await _channel!.waitForConnected();

        print('gRPC channel established successfully!');
        _initializeCompleter!.complete();
        return; // Exit the loop on success
      } catch (e) {
        retryAttempt++;
        _channel = null;
        _helloClient = null;
        _sumClient = null;

        if (retryAttempt >= _maxRetries) {
          final error = Exception(
              'Failed to establish gRPC connection after $_maxRetries attempts: $e');
          _initializeCompleter!.completeError(error);
          throw error;
        }

        final delay = _getExponentialBackoffWithJitter(retryAttempt);
        print(
            'Connection failed, retrying in ${delay.inSeconds}s (Attempt $retryAttempt)...');
        await Future.delayed(delay);
      }
    }

    // Handle case where loop exits due to shutdown
    if (!_initializeCompleter!.isCompleted) {
      _initializeCompleter!.completeError(
          Exception("Initialization cancelled due to shutdown."));
    }
  }

  Duration _getExponentialBackoffWithJitter(int attempt) {
    // Ensure correct numerical types for calculations
    final baseDelay = pow(2, attempt).toDouble();
    final jitter = Random().nextDouble() * baseDelay;

    // Limit the maximum delay to 60 seconds
    final delayInSeconds = min(baseDelay + jitter, 60.0).toInt();

    return Duration(seconds: delayInSeconds);
  }

  /// Executes a gRPC call with automatic retries and reconnection on failure.
  Future<R> safeCall<R>(Future<R> Function() call) async {
    int retryAttempt = 0;

    while (!_isShutdown && retryAttempt < _maxRetries) {
      try {
        // Ensure channel is initialized before calling
        await _getClientAsync(() => null, (c) => null);
        return await call();
      } catch (e) {
        retryAttempt++;

        // Do not retry on gRPC status errors (like NOT_FOUND or PERMISSION_DENIED)
        if (e is GrpcError && e.code != StatusCode.unavailable) {
          print('Non-retryable gRPC error: $e');
          throw e;
        }

        print(
            'Call failed (likely connection issue): $e. Attempting reconnect (${retryAttempt}/$_maxRetries)...');

        if (retryAttempt >= _maxRetries) {
          throw Exception('Call failed after $_maxRetries retries: $e');
        }
        await _reconnectWithBackoff(retryAttempt);
      }
    }

    throw Exception('GRPC client shutdown or retry limit reached.');
  }

  Future<void> _reconnectWithBackoff(int attempt) async {
    // Ensure channel is terminated before attempting a new one
    await _terminateChannel();

    final delay = _getExponentialBackoffWithJitter(attempt);
    await Future.delayed(delay);
    await _initializeChannel();
  }

  /// Terminates the channel immediately and resets state.
  Future<void> _terminateChannel() async {
    if (_channel != null) {
      await _channel!
          .terminate(); // Use terminate for immediate resource cleanup
    }
    _channel = null;
    _helloClient = null;
    _sumClient = null;
  }

  /// Gracefully shuts down the client for application termination.
  Future<void> shutdown() async {
    _isShutdown = true; // FIX: Should be true when shutting down

    if (_channel != null) {
      // Use shutdown for a graceful exit, allowing any inflight requests to complete
      await _channel!.shutdown();
    }
    _channel = null;
    _helloClient = null;
    _sumClient = null;
    _isShutdown = false;

    // Ensure completer is cleared
    _initializeCompleter = null;
  }
}
