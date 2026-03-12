import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class MarketRemoteDataSource {
  Stream<List<dynamic>> getMarketStream({
    required String vsCurrency,
    required int perPage,
    required int page,
  });
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final HttpClient _client = HttpClient();

  // Helper for dynamic base URL depending on platform emulator vs device
  String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api';

  @override
  Stream<List<dynamic>> getMarketStream({
    required String vsCurrency,
    required int perPage,
    required int page,
  }) async* {
    final uri = Uri.parse('$baseUrl/market/stream?vs_currency=$vsCurrency&per_page=$perPage&page=$page');

    while (true) {
      HttpClientRequest? request;
      HttpClientResponse? response;
      try {
        request = await _client.getUrl(uri);
        request.headers.add('Accept', 'text/event-stream');
        request.headers.add('Cache-Control', 'no-cache');
        
        response = await request.close();

        if (response.statusCode == 200) {
          // Decode the stream
          final stream = response
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in stream) {
            if (line.startsWith('data: ')) {
              final dataString = line.substring(6);
              try {
                final Map<String, dynamic> jsonResponse = jsonDecode(dataString);
                if (jsonResponse['success'] == true) {
                  yield jsonResponse['data'] as List<dynamic>;
                }
              } catch (e) {
                debugPrint('SSE JSON Decode Error: $e');
              }
            }
          }
        } else {
           debugPrint('SSE Connection failed with status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('SSE Connection Error: $e');
      }

      // If stream breaks, wait 5 seconds before attempting to reconnect
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
