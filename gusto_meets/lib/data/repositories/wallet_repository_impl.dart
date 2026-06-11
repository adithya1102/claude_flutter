import '../../core/errors/app_exception.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/supabase_wallet_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseWalletSource _source;
  WalletRepositoryImpl(this._source);

  // In-memory mock wallet transactions and balances
  static double _mockBalance = 1000.0;
  static final List<WalletTransactionEntity> _mockTransactions = [];

  @override
  Future<double> getBalance(String userId) async {
    if (userId == 'mock-user-1234') {
      return _mockBalance;
    }
    try {
      return await _source.getBalance(userId);
    } catch (e) {
      print('getBalance failed: $e. Returning mock balance.');
      return _mockBalance;
    }
  }

  @override
  Future<List<WalletTransactionEntity>> getTransactions(String userId) async {
    if (userId == 'mock-user-1234') {
      return _mockTransactions;
    }
    try {
      final list = await _source.getTransactions(userId);
      if (list.isEmpty) return _mockTransactions;
      return list;
    } catch (e) {
      print('getTransactions failed: $e. Returning mock transactions.');
      return _mockTransactions;
    }
  }

  @override
  Future<void> debitWallet(
      String userId, double amount, String description, String? bookingId) async {
    if (userId == 'mock-user-1234') {
      _mockBalance -= amount;
      _mockTransactions.insert(
        0,
        WalletTransactionEntity(
          id: 'tx-mock-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          amount: -amount,
          balanceAfter: _mockBalance,
          description: description,
          bookingId: bookingId,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    try {
      await _source.debitWallet(userId, amount, description, bookingId);
    } catch (e) {
      print('debitWallet failed: $e. Debiting mock wallet locally.');
      _mockBalance -= amount;
      _mockTransactions.insert(
        0,
        WalletTransactionEntity(
          id: 'tx-mock-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          amount: -amount,
          balanceAfter: _mockBalance,
          description: description,
          bookingId: bookingId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> creditWallet(String userId, double amount, String description,
      String? razorpayPaymentId) async {
    if (userId == 'mock-user-1234') {
      _mockBalance += amount;
      _mockTransactions.insert(
        0,
        WalletTransactionEntity(
          id: 'tx-mock-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          amount: amount,
          balanceAfter: _mockBalance,
          description: description,
          bookingId: null,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    try {
      await _source.creditWallet(userId, amount, description, razorpayPaymentId);
    } catch (e) {
      print('creditWallet failed: $e. Crediting mock wallet locally.');
      _mockBalance += amount;
      _mockTransactions.insert(
        0,
        WalletTransactionEntity(
          id: 'tx-mock-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          amount: amount,
          balanceAfter: _mockBalance,
          description: description,
          bookingId: null,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}
