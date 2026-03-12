abstract class MarketRepository {
  /// Connects to the SSE stream and yields continuous updates of the market data list.
  Stream<List<dynamic>> getMarketStream({
    String vsCurrency = 'usd',
    int perPage = 10,
    int page = 1,
  });
}
