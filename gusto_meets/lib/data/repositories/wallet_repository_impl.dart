import '../../core/errors/app_exception.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/supabase_wallet_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseWalletSource _source;
  WalletRepositoryImpl(this._source);

  @override
  Future<double> getBalance(String userId) async {
    try {
      return await _source.getBalance(userId);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<WalletTransactionEntity>> getTransactions(String userId) async {
    try {
      return await _source.getTransactions(userId);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> debitWallet(
      String userId, double amount, String description, String? bookingId) async {
    try {
      await _source.debitWallet(userId, amount, description, bookingId);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> creditWallet(String userId, double amount, String description,
      String? razorpayPaymentId) async {
    try {
      await _source.creditWallet(userId, amount, description, razorpayPaymentId);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }
}
