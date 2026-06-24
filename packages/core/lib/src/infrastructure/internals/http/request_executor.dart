import 'dart:convert';
import 'dart:io';

import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';

final class RequestExecutor {
  final HttpClientContract client;
  final LoggerContract logger;

  RequestExecutor({required this.client, required this.logger});

  Future<T> send<T>(RequestContract request, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final response = await client.send(request);

      if (response.statusCode == 429) {
        if (attempt == maxRetries) {
          throw HttpException('Rate limit exceeded after $maxRetries retries');
        }

        final retryAfter = response.body['retry_after'];
        final seconds = double.parse(retryAfter.toString()).toInt() + 1;
        logger.warn(
          'Rate limit reached, retrying in $seconds seconds (attempt ${attempt + 1}/$maxRetries)',
        );
        await Future.delayed(Duration(seconds: seconds));
        continue;
      }

      return switch (response.statusCode) {
            _ when [404, 401, 500].contains(response.statusCode) => throwError(
              response,
            ),
            _ => response.body,
          }
          as T;
    }

    throw HttpException('Unexpected: exhausted retries');
  }

  void throwError(Response response, {String? message}) {
    final data = {
      'method': response.method,
      'statusCode': response.statusCode,
      'reason': response.reasonPhrase,
      'url': response.uri.toString(),
    };

    throw HttpException(jsonEncode(data));
  }
}
