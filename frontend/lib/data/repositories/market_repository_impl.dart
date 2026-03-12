import '../../domain/repositories/market_repository.dart';
import '../datasources/market_remote_data_source.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource remoteDataSource;

  MarketRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<dynamic>> getMarketStream({
    String vsCurrency = 'usd',
    int perPage = 10,
    int page = 1,
  }) {
    return remoteDataSource.getMarketStream(
      vsCurrency: vsCurrency,
      perPage: perPage,
      page: page,
    );
  }

  @override
  Future<List<dynamic>> getAssetHistory({
    required String coinId,
    String days = '7',
  }) {
    return remoteDataSource.getAssetHistory(
      coinId: coinId,
      days: days,
    );
  }
}
