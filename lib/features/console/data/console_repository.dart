import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:nocturne/features/console/domain/console_summary.dart';

/// Reads the Worker's aggregate snapshot with the owner's console token.
class ConsoleRepository {
  /// The caller owns [client] and closes it with the provider that made it.
  const ConsoleRepository({required this.client, required this.endpoint});

  /// HTTP client, injected so no test reaches the network.
  final http.Client client;

  /// The Worker's `/v1/aggregates` URL.
  final Uri endpoint;

  /// Fetches and summarises the last [days] of counters.
  ///
  /// Throws [ConsoleAuthException] on a rejected token so the screen can ask
  /// again rather than showing an empty dashboard, which would read as "no
  /// traffic" when it actually means "wrong password".
  Future<ConsoleSummary> summary({
    required String token,
    required DateTime today,
    int days = 30,
  }) async {
    final result = await client.get(
      endpoint,
      headers: {'authorization': 'Bearer $token'},
    );
    if (result.statusCode == 401 || result.statusCode == 403) {
      throw const ConsoleAuthException();
    }
    if (result.statusCode != 200) {
      throw ConsoleUnavailableException(result.statusCode);
    }

    final body = jsonDecode(result.body);
    if (body is! Map<String, dynamic>) {
      throw const ConsoleUnavailableException(200);
    }

    return ConsoleSummary.from(
      counters: _counters(body['counters']),
      totals: _totals(body['totals']),
      today: today,
      days: days,
    );
  }

  List<CounterRow> _counters(Object? raw) => [
    if (raw is List)
      for (final row in raw)
        if (row is Map<String, dynamic>)
          (
            dimensions: _dimensions(row['dimensions']),
            count: _int(row['count']),
          ),
  ];

  List<TotalRow> _totals(Object? raw) => [
    if (raw is List)
      for (final row in raw)
        if (row is Map<String, dynamic>)
          (
            dimensions: _dimensions(row['dimensions']),
            total: _int(row['total']),
          ),
  ];

  List<String> _dimensions(Object? raw) => [
    if (raw is List)
      for (final value in raw) '$value',
  ];

  int _int(Object? raw) => raw is num ? raw.toInt() : 0;
}

/// The token was rejected.
class ConsoleAuthException implements Exception {
  /// Creates the exception.
  const ConsoleAuthException();

  @override
  String toString() => 'Console token rejected.';
}

/// The endpoint could not be read; the status is kept, the body is not.
class ConsoleUnavailableException implements Exception {
  /// Records the response without retaining its body.
  const ConsoleUnavailableException(this.statusCode);

  /// Worker response status.
  final int statusCode;

  @override
  String toString() => 'Console unavailable ($statusCode).';
}
