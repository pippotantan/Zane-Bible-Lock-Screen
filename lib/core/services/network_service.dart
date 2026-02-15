import 'dart:async';
import 'dart:io';

class NetworkService {
  /// Check if device has network connectivity by attempting DNS lookup
  static Future<bool> hasNetworkConnection() async {
    try {
      print('[NetworkService] Checking network connectivity via DNS lookup');

      // Attempt to lookup a well-known DNS (Google's)
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      print('[NetworkService] Network connection check: $hasConnection');
      return hasConnection;
    } catch (e) {
      print(
        '[NetworkService] Network check failed ($e) - assuming no connection',
      );
      return false;
    }
  }

  /// Wait for network connection with retry
  static Future<bool> waitForNetworkConnection({
    Duration timeout = const Duration(seconds: 15),
    Duration retryInterval = const Duration(seconds: 2),
  }) async {
    try {
      print('[NetworkService] Waiting for network connection...');

      final startTime = DateTime.now();

      while (DateTime.now().difference(startTime) < timeout) {
        final hasConnection = await hasNetworkConnection();
        if (hasConnection) {
          print('[NetworkService] Network connection restored');
          return true;
        }

        print(
          '[NetworkService] No connection yet, retrying in ${retryInterval.inSeconds}s...',
        );
        await Future.delayed(retryInterval);
      }

      print('[NetworkService] Timeout waiting for network connection');
      return false;
    } catch (e) {
      print('[NetworkService] Error waiting for network: $e');
      return false;
    }
  }
}
