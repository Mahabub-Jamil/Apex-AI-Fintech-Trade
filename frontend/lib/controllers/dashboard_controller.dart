import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/auth_controller.dart';
import '../domain/repositories/market_repository.dart';

class DashboardController extends GetxController {
  final MarketRepository marketRepository;
  final Dio _dio = Dio();
  
  DashboardController({required this.marketRepository});
  
  // Observables
  var isLoading = true.obs;
  var balanceUSD = 0.00.obs;
  var balanceBDT = 0.00.obs;
  var totalInvestedUSD = 0.00.obs;
  var totalProfitUSD = 0.00.obs;
  var marketData = [].obs;
  var aiPortfolioStrategy = ''.obs;
  
  // To track individual coin P&L on the UI
  var coinPnL = <String, double>{}.obs;
  
  // Stream subscription for SSE cleanup
  StreamSubscription? _marketSubscription;

  String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api';

  @override
  void onInit() {
    super.onInit();
    
    // Bind market stream
    _marketSubscription = marketRepository.getMarketStream().listen(
      (data) {
        isLoading(false);
        marketData.value = data;
      },
      onError: (err) {
        print("Market Stream Error: $err");
        isLoading(false);
      }
    );
    
    // Still need to fetch AI data manually just once or on demand
    fetchAIPortfolioStrategy();
    
    // Reactively compute balances when market or user data changes
    ever(marketData, (_) => calculatePortfolioValue());
    final authController = Get.find<AuthController>();
    ever(authController.firestoreUserData, (_) {
      calculatePortfolioValue();
      fetchAIPortfolioStrategy();
    });
  }

  @override
  void onClose() {
    _marketSubscription?.cancel();
    super.onClose();
  }

  void calculatePortfolioValue() {
    try {
      final authController = Get.find<AuthController>();
      final userData = authController.firestoreUserData;
      
      double cashBalance = (userData['balanceUSD'] ?? 0.0) is int 
          ? (userData['balanceUSD'] as int).toDouble() 
          : (userData['balanceUSD'] ?? 0.0) as double;
          
      double realizedProfit = (userData['realizedProfit'] ?? 0.0) is int
          ? (userData['realizedProfit'] as int).toDouble()
          : (userData['realizedProfit'] ?? 0.0) as double;
          
      double totalAssetsValue = 0.0;
      double totalAssetsCost = 0.0;
      
      Map<String, dynamic> holdings = userData['holdings'] ?? {};
      
      for (var entry in holdings.entries) {
        String symbol = entry.key.toLowerCase();
        
        // Handle both old format (double) and new format (Map) just in case
        double amount = 0.0;
        double costBasis = 0.0;

        if (entry.value is Map) {
          final holdingMap = entry.value as Map;
          amount = (holdingMap['amount'] ?? 0.0) is int ? (holdingMap['amount'] as int).toDouble() : (holdingMap['amount'] ?? 0.0) as double;
          costBasis = (holdingMap['costBasis'] ?? 0.0) is int ? (holdingMap['costBasis'] as int).toDouble() : (holdingMap['costBasis'] ?? 0.0) as double;
        } else {
          amount = entry.value is int ? (entry.value as int).toDouble() : (entry.value as double);
        }
        
        var coinData = marketData.firstWhere(
            (coin) => coin['symbol'].toString().toLowerCase() == symbol || coin['id'].toString().toLowerCase() == symbol, 
            orElse: () => null
        );
        
        if (coinData != null) {
          double currentPrice = coinData['current_price'] is int 
              ? (coinData['current_price'] as int).toDouble() 
              : (coinData['current_price'] as double);
          
          double currentValue = amount * currentPrice;
          double investmentValue = amount * costBasis;
          
          totalAssetsValue += currentValue;
          totalAssetsCost += investmentValue;

          // Calculate Percentage Profit/Loss per coin
          if (costBasis > 0) {
            double profitPct = ((currentPrice - costBasis) / costBasis) * 100;
            coinPnL[symbol] = profitPct;
          } else {
            coinPnL[symbol] = 0.0;
          }
        }
      }
      
      double totalUsd = cashBalance + totalAssetsValue;
      
      balanceUSD.value = totalUsd;
      totalInvestedUSD.value = totalAssetsCost;
      totalProfitUSD.value = realizedProfit + (totalAssetsValue - totalAssetsCost);
      balanceBDT.value = totalUsd * 110.0; // Example conversion rate
    } catch (e) {
      print("Valuation Error: $e");
    }
  }

  Future<void> fetchAIPortfolioStrategy() async {
    try {
      isLoading(true);

      // Formulate Portfolio Array for AI Advice
      final authController = Get.find<AuthController>();
      final userData = authController.firestoreUserData;
      Map<String, dynamic> holdings = userData['holdings'] ?? {};
      
      List<Map<String, dynamic>> portfolioArray = [];
      
      for (var entry in holdings.entries) {
        String symbol = entry.key.toLowerCase();
        double amount = 0.0;
        
        if (entry.value is Map) {
          final holdingMap = entry.value as Map;
          amount = (holdingMap['amount'] ?? 0.0) is int ? (holdingMap['amount'] as int).toDouble() : (holdingMap['amount'] ?? 0.0) as double;
        } else {
          amount = entry.value is int ? (entry.value as int).toDouble() : (entry.value as double);
        }
        
        if (amount > 0) {
          var coinData = marketData.firstWhere(
              (coin) => coin['symbol'].toString().toLowerCase() == symbol || coin['id'].toString().toLowerCase() == symbol,  
              orElse: () => null
          );
          double currentValue = 0.0;
          if (coinData != null) {
              double currentPrice = coinData['current_price'] is int ? (coinData['current_price'] as int).toDouble() : (coinData['current_price'] as double);
              currentValue = amount * currentPrice;
          }
          portfolioArray.add({
            'symbol': symbol.toUpperCase(),
            'amount': amount,
            'currentValue': currentValue
          });
        }
      }

      // Fetch AI Strategy Review
      if (portfolioArray.isNotEmpty) {
          final adviseResponse = await _dio.post('$baseUrl/ai/advise', data: {
            'portfolio': portfolioArray,
            'riskTolerance': 'MEDIUM'
          });

          if (adviseResponse.statusCode == 200 && adviseResponse.data['success'] == true) {
            aiPortfolioStrategy.value = adviseResponse.data['advice'];
          }
      } else {
         // Fallback if no holdings
         aiPortfolioStrategy.value = "Your portfolio is currently empty. Head to the Portfolio tab to execute mock trades and receive AI strategy advice based on your holdings.";
      }
      
    } catch (e) {
      print("Dashboard Error: $e");
      // Fallback data if backend is not running
      if (marketData.isEmpty) {
        marketData.value = [
          {'symbol': 'btc', 'current_price': 65000.0, 'price_change_percentage_24h': 2.5},
          {'symbol': 'eth', 'current_price': 3500.0, 'price_change_percentage_24h': 1.2},
          {'symbol': 'sol', 'current_price': 150.0, 'price_change_percentage_24h': -0.5},
        ];
      }
      aiPortfolioStrategy.value = 'Insight unavailable';
    } finally {
      isLoading(false);
    }
  }
}
