import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';
import '../controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final Dio _dio = Dio();
  
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
  
  // Background polling timer
  Timer? _refreshTimer;

  String get baseUrl {
    if (GetPlatform.isAndroid) {
      return 'http://192.168.0.101:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    
    // Start automatic background refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchDashboardData();
    });
    
    // Reactively compute balances when market or user data changes
    ever(marketData, (_) => calculatePortfolioValue());
    final authController = Get.find<AuthController>();
    ever(authController.firestoreUserData, (_) => calculatePortfolioValue());
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void calculatePortfolioValue() {
    try {
      final authController = Get.find<AuthController>();
      final userData = authController.firestoreUserData;
      
      double cashBalance = (userData['balanceUSD'] ?? 0.0) is int 
          ? (userData['balanceUSD'] as int).toDouble() 
          : (userData['balanceUSD'] ?? 0.0) as double;
          
      double totalUsd = cashBalance;
      double totalInvested = cashBalance; // Cash counts as retained value not yet "invested", but part of net worth.
      
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
            (coin) => coin['symbol'] == symbol, 
            orElse: () => null
        );
        
        if (coinData != null) {
          double currentPrice = coinData['current_price'] is int 
              ? (coinData['current_price'] as int).toDouble() 
              : (coinData['current_price'] as double);
          
          double currentValue = amount * currentPrice;
          double investmentValue = amount * costBasis;
          
          totalUsd += currentValue;
          totalInvested += investmentValue;

          // Calculate Percentage Profit/Loss per coin
          if (costBasis > 0) {
            double profitPct = ((currentPrice - costBasis) / costBasis) * 100;
            coinPnL[symbol] = profitPct;
          } else {
            coinPnL[symbol] = 0.0;
          }
        }
      }
      
      balanceUSD.value = totalUsd;
      totalInvestedUSD.value = totalInvested;
      totalProfitUSD.value = totalUsd - totalInvested;
      balanceBDT.value = totalUsd * 110.0; // Example conversion rate
    } catch (e) {
      print("Valuation Error: $e");
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading(true);
      // Fetch market stream
      final marketResponse = await _dio.get('$baseUrl/market/stream', queryParameters: {
        'vs_currency': 'usd',
        'per_page': 10,
      });

      if (marketResponse.statusCode == 200 && marketResponse.data['success'] == true) {
        marketData.value = marketResponse.data['data'];
      }
      
      // Calculate balances immediately with new market data so we can pass accurate values to AI
      calculatePortfolioValue();

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
              (coin) => coin['symbol'] == symbol, 
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
