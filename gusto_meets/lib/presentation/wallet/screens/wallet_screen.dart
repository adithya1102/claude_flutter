import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/wallet_transaction_entity.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/gusto_button.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late Razorpay _razorpay;
  double _addAmount = 500;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handleSuccess(PaymentSuccessResponse res) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    await ref.read(walletRepoProvider).creditWallet(
      user.id,
      _addAmount,
      'Wallet top-up via Razorpay',
      res.paymentId,
    );
    ref.invalidate(currentUserProvider);
    ref.invalidate(_txnsProvider(user.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${CurrencyUtils.formatINR(_addAmount)} added to wallet'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleError(PaymentFailureResponse res) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${res.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openAddMoney() {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Money',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [200.0, 500.0, 1000.0, 2000.0].map((amt) {
                return ChoiceChip(
                  label: Text(CurrencyUtils.formatINR(amt)),
                  selected: _addAmount == amt,
                  onSelected: (_) =>
                      setState(() => _addAmount = amt),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _addAmount == amt
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(hintText: 'Custom amount'),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) setState(() => _addAmount = parsed);
              },
            ),
            const SizedBox(height: 16),
            GustoButton(
              onPressed: () {
                Navigator.pop(context);
                _payToAdd();
              },
              label:
                  'Add ${CurrencyUtils.formatINR(_addAmount)}',
            ),
          ],
        ),
      ),
    );
  }

  void _payToAdd() {
    final user = ref.read(currentUserProvider).value;
    final options = {
      'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
      'amount': (_addAmount * 100).toInt(),
      'name': 'Gusto Meets',
      'description': 'Wallet top-up',
      'prefill': {'contact': '+91${user?.phoneNumber ?? ''}'},
      'theme': {'color': '#10B981'},
    };
    _razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final txnsAsync = user != null
        ? ref.watch(_txnsProvider(user.id))
        : const AsyncValue<List<WalletTransactionEntity>>.loading();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  CurrencyUtils.formatINR(
                      user?.walletBalance ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _openAddMoney,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Add Money'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Transactions',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: txnsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) {
                if (txns.isEmpty) {
                  return const Center(
                      child: Text(
                    'No transactions yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: txns.length,
                  itemBuilder: (_, i) {
                    final tx = txns[i];
                    final showHeader = i == 0 ||
                        !_sameDay(
                            txns[i - 1].createdAt, tx.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            child: Text(
                              _dateHeader(tx.createdAt),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        _TxnRow(txn: tx),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  String _dateHeader(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return AppDateUtils.formatDate(d);
  }
}

final _txnsProvider = FutureProvider.autoDispose
    .family<List<WalletTransactionEntity>, String>((ref, userId) {
  return ref.watch(walletRepoProvider).getTransactions(userId);
});

class _TxnRow extends StatelessWidget {
  final WalletTransactionEntity txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: txn.isCredit
                  ? AppColors.primaryLight
                  : const Color(0xFFFFE4E6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: txn.isCredit ? AppColors.primary : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppDateUtils.formatTime(txn.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${txn.isCredit ? '+' : '-'}${CurrencyUtils.formatINR(txn.amount.abs())}',
            style: TextStyle(
              color: txn.isCredit ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
