import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';

/// ---------------- BASE ----------------
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// ---------------- NETWORK ----------------
class NoInternetException extends AppException {
  const NoInternetException() : super("No internet connection");
}

class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException() : super("Request timed out");
}

class HostLookupException extends AppException {
  const HostLookupException() : super("Unable to reach server");
}

class SocketFailureException extends AppException {
  const SocketFailureException() : super("Network error occurred");
}

class UnknownException extends AppException {
  const UnknownException() : super("Something went wrong");
}

/// ---------------- MAPPER ----------------
AppException mapException(Object error) {
  // 1️⃣ SocketException (DNS, offline, network)
  if (error is SocketException) {
    if (error.message.contains('Failed host lookup')) {
      return const HostLookupException();
    }
    return const NoInternetException();
  }

  // 2️⃣ Timeout
  if (error is TimeoutException) {
    return const NetworkTimeoutException();
  }

  // 3️⃣ HTTP ClientException
  if (error is ClientException) {
    return const SocketFailureException();
  }

  // 4️⃣ Already mapped
  if (error is AppException) {
    return error;
  }

  // 5️⃣ Fallback (MANDATORY)
  return const UnknownException();
}
