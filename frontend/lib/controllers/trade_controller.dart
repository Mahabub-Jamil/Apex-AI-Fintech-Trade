import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_controller.dart';
import 'dart:io';

class TradeController extends GetxController {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var isLoading = false.obs;

  String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api';

  Future<bool> executeTrade(String coinId, String symbol, double amount, double currentPrice, bool isBuy) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.user.value;
      if (user == null) {
        Get.snackbar("Error", "Must be logged in to trade");
        return false;
      }

      var userData = authController.firestoreUserData;
      double balanceUSD = (userData['balanceUSD'] ?? 0.0) is int 
          ? (userData['balanceUSD'] as int).toDouble() 
          : (userData['balanceUSD'] ?? 0.0) as double;
      
      String holdingKey = symbol.toLowerCase();
      String legacyKey = coinId.toLowerCase();
      
      Map<String, dynamic> holdings = Map<String, dynamic>.from(userData['holdings'] ?? {});
      
      // Migrate legacy key (e.g., 'bitcoin' -> 'btc')
      if (holdings.containsKey(legacyKey) && holdingKey != legacyKey) {
        var oldHoldings = holdings[legacyKey];
        var newHoldings = holdings[holdingKey];
        
        double oldAmount = oldHoldings is Map ? ((oldHoldings['amount'] ?? 0.0) as num).toDouble() : (oldHoldings is num ? oldHoldings.toDouble() : 0.0);
        double oldCostBasis = oldHoldings is Map ? ((oldHoldings['costBasis'] ?? 0.0) as num).toDouble() : currentPrice;
        
        double newAmount = newHoldings is Map ? ((newHoldings['amount'] ?? 0.0) as num).toDouble() : 0.0;
        double newCostBasis = newHoldings is Map ? ((newHoldings['costBasis'] ?? 0.0) as num).toDouble() : 0.0;
        
        double totalAmount = oldAmount + newAmount;
        double totalCost = (oldAmount * oldCostBasis) + (newAmount * newCostBasis);
        double avgCostBasis = totalAmount > 0 ? (totalCost / totalAmount) : 0.0;
        
        holdings[holdingKey] = {
           'amount': totalAmount,
           'costBasis': avgCostBasis
        };
        holdings.remove(legacyKey);
      }
      
      Map<String, dynamic> currentHoldingData = holdings[holdingKey] is Map 
          ? Map<String, dynamic>.from(holdings[holdingKey] as Map) 
          // support legacy format where the value was just a double
          : holdings[holdingKey] is num 
             ? {'amount': (holdings[holdingKey] as num).toDouble(), 'costBasis': currentPrice}
             : {'amount': 0.0, 'costBasis': 0.0};
          
      double currentAmount = (currentHoldingData['amount'] ?? 0.0) is int 
          ? (currentHoldingData['amount'] as int).toDouble() 
          : (currentHoldingData['amount'] ?? 0.0) as double;
          
      double currentCostBasis = (currentHoldingData['costBasis'] ?? 0.0) is int
          ? (currentHoldingData['costBasis'] as int).toDouble()
          : (currentHoldingData['costBasis'] ?? 0.0) as double;

      double tradeValue = amount * currentPrice;

      if (isBuy) {
        if (balanceUSD < tradeValue) {
          Get.snackbar("Insufficient Funds", "You need \$${tradeValue.toStringAsFixed(2)} to complete this mock trade.");
          return false;
        }
        balanceUSD -= tradeValue;
        
        // Calculate new weighted average cost basis
        double totalCost = (currentAmount * currentCostBasis) + tradeValue;
        currentAmount += amount;
        currentCostBasis = totalCost / currentAmount;
        
      } else {
        if (currentAmount < amount) {
          Get.snackbar("Insufficient Holdings", "You only have ${currentAmount.toStringAsFixed(4)} $symbol.");
          return false;
        }
        balanceUSD += tradeValue;
        currentAmount -= amount;
        // Cost basis per unit doesn't change on a sale. 
        if (currentAmount <= 0) {
          currentCostBasis = 0.0; // Reset if completely sold out
        }
      }

      // Update Local Map for immediate reactivity
      holdings[holdingKey] = {
        'amount': currentAmount,
        'costBasis': currentCostBasis
      };
      
      // Hit Backend API for validation/record
      final response = await _dio.post('$baseUrl/user/trade', data: {
        'userId': user.uid,
        'assetSymbol': symbol.toUpperCase(),
        'side': isBuy ? 'BUY' : 'SELL',
        'amount': amount,
        'priceAtTrade': currentPrice
      });

      if (response.statusCode == 200) {
        // Update Firestore User Document
        await _firestore.collection('users').doc(user.uid).update({
          'balanceUSD': balanceUSD,
          'holdings': holdings
        });

        // Update local auth controller Map
        userData['balanceUSD'] = balanceUSD;
        userData['holdings'] = holdings;
        authController.firestoreUserData.refresh();

        Get.snackbar("Trade Successful", "Successfully ${isBuy ? 'bought' : 'sold'} $amount $symbol for \$${tradeValue.toStringAsFixed(2)}", 
          snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        Get.snackbar("Server Error", "Could not process trade.");
        return false;
      }

    } catch (e) {
      print("Trade execution error: $e");
      String errMsg = "An unexpected error occurred.";
      if (e is DioException) {
        String serverErr = e.message ?? 'Unknown Dio error';
        if (e.response?.data != null) {
           if (e.response!.data! is Map) {
              serverErr = e.response!.data!['error'] ?? serverErr;
           } else {
              serverErr = e.response!.data!.toString();
           }
        }
        errMsg = "Network/API error: ${e.response?.statusCode} - $serverErr";
      } else {
         errMsg = e.toString();
      }
      Get.snackbar("Error", errMsg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
