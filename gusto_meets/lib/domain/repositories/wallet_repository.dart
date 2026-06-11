import '../entities/wallet_transaction_entity.dart';

abstract class WalletRepository {
  Future<double> getBalance(String userId);
  Future<List<WalletTransactionEntity>> getTransactions(String userId);
  Future<void> debitWallet(
      String userId, double amount, String description, String? bookingId);
  Future<void> creditWallet(
      String userId, double amount, String description, String? razorpayPaymentId);
}
