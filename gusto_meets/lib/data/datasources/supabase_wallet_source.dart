import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../core/constants/supabase_tables.dart';

class SupabaseWalletSource {
  final SupabaseClient _client;
  SupabaseWalletSource(this._client);

  Future<double> getBalance(String userId) async {
    final data = await _client
        .from(SupabaseTables.users)
        .select('wallet_balance')
        .eq('id', userId)
        .single();
    return (data['wallet_balance'] as num).toDouble();
  }

  Future<List<WalletTransactionEntity>> getTransactions(String userId) async {
    final result = await _client
        .from(SupabaseTables.walletTransactions)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (result as List<dynamic>)
        .map((m) =>
            WalletTransactionEntity.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> debitWallet(
      String userId, double amount, String description, String? bookingId) async {
    final balance = await getBalance(userId);
    final newBalance = balance - amount;
    await _client
        .from(SupabaseTables.users)
        .update({'wallet_balance': newBalance}).eq('id', userId);
    await _client.from(SupabaseTables.walletTransactions).insert({
      'user_id': userId,
      'amount': -amount,
      'balance_after': newBalance,
      'description': description,
      'booking_id': bookingId,
    });
  }

  Future<void> creditWallet(String userId, double amount, String description,
      String? razorpayPaymentId) async {
    final balance = await getBalance(userId);
    final newBalance = balance + amount;
    await _client
        .from(SupabaseTables.users)
        .update({'wallet_balance': newBalance}).eq('id', userId);
    await _client.from(SupabaseTables.walletTransactions).insert({
      'user_id': userId,
      'amount': amount,
      'balance_after': newBalance,
      'description': description,
      'razorpay_payment_id': razorpayPaymentId,
    });
  }
}
