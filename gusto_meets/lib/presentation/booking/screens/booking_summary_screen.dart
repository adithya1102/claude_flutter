import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/terrace_entity.dart';
import '../../../domain/enums/booking_purpose.dart';
import '../../../domain/enums/booking_status.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/gusto_button.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const BookingSummaryScreen({super.key, required this.data});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState
    extends ConsumerState<BookingSummaryScreen> {
  bool _waiverChecked = false;
  bool _isLoading = false;
  late Razorpay _razorpay;
  String? _pendingBookingId;

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

  TerraceEntity? get _terrace => widget.data['terrace'] as TerraceEntity?;
  DateTime? get _startTime => widget.data['startTime'] as DateTime?;
  DateTime? get _endTime => widget.data['endTime'] as DateTime?;
  BookingPurpose? get _purpose =>
      widget.data['purpose'] as BookingPurpose?;
  int get _guestCount => widget.data['guestCount'] as int? ?? 1;
  double get _baseCost => widget.data['baseCost'] as double? ?? 0;
  double get _purposePremium =>
      widget.data['purposePremium'] as double? ?? 0;
  double get _platformFee =>
      widget.data['platformFee'] as double? ?? 0;
  double get _securityDeposit =>
      widget.data['securityDeposit'] as double? ?? 0;
  double get _total => widget.data['total'] as double? ?? 0;
  double get _totalHours =>
      widget.data['totalHours'] as double? ?? 0;

  void _handleSuccess(PaymentSuccessResponse response) async {
    final bookingId = _pendingBookingId;
    if (bookingId == null) return;
    try {
      await ref
          .read(bookingRepoProvider)
          .confirmBooking(bookingId, response.paymentId ?? '');
      if (mounted) context.go('/bookings/active/$bookingId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded but booking update failed: $e')),
        );
      }
    }
  }

  void _handleError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pay() async {
    final terrace = _terrace;
    final start = _startTime;
    final end = _endTime;
    final user = ref.read(currentUserProvider).value;
    if (terrace == null || start == null || end == null || user == null) return;

    setState(() => _isLoading = true);
    try {
      final booking = BookingEntity(
        id: '',
        guestId: user.id,
        terraceId: terrace.id,
        startTime: start,
        endTime: end,
        extensionsCount: 0,
        purpose: _purpose ?? BookingPurpose.chillout,
        guestCount: _guestCount,
        status: BookingStatus.pendingPayment,
        hourlyRateApplied: terrace.baseHourlyRate,
        totalHours: _totalHours,
        totalTimeCost: _baseCost + _purposePremium,
        securityDepositHeld: _securityDeposit,
        platformFee: _platformFee,
        overstayPenalty: 0,
        damagePenalty: 0,
        digitalWaiverSigned: _waiverChecked,
        hostCheckedIn: false,
        createdAt: DateTime.now(),
      );
      final created =
          await ref.read(bookingRepoProvider).createBooking(booking);
      _pendingBookingId = created.id;

      final options = {
        'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
        'amount': (_total * 100).toInt(),
        'name': 'Gusto Meets',
        'description': 'Terrace: ${terrace.title}',
        'prefill': {'contact': '+91${user.phoneNumber}'},
        'theme': {'color': '#10B981'},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Booking failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final terrace = _terrace;
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Pay')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard('Booking Details', [
              _detailRow(
                  'Terrace', terrace?.title ?? ''),
              _detailRow(
                  'Date',
                  _startTime != null
                      ? AppDateUtils.formatDate(_startTime!)
                      : ''),
              _detailRow(
                  'Time',
                  _startTime != null && _endTime != null
                      ? '${AppDateUtils.formatTime(_startTime!)} – ${AppDateUtils.formatTime(_endTime!)}'
                      : ''),
              _detailRow(
                  'Duration',
                  '${_totalHours.toStringAsFixed(1)} hours'),
              _detailRow(
                  'Purpose',
                  _purpose?.displayName ?? 'Not specified'),
              _detailRow('Guests', '$_guestCount'),
            ]),
            const SizedBox(height: 16),
            _sectionCard('Pricing Breakdown', [
              _detailRow('Base cost',
                  CurrencyUtils.formatINR(_baseCost)),
              if (_purposePremium > 0)
                _detailRow('Purpose premium',
                    CurrencyUtils.formatINR(_purposePremium)),
              _detailRow('Platform fee (15%)',
                  CurrencyUtils.formatINR(_platformFee)),
              if (_securityDeposit > 0)
                _detailRow('Security deposit',
                    CurrencyUtils.formatINR(_securityDeposit)),
              const Divider(height: 20),
              Row(
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text(
                    CurrencyUtils.formatINR(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            if (user?.kycVerified == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Identity verified as ${user!.kycVerifiedName ?? user.fullName}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  'TERMS & WAIVER\n\n'
                  '1. The guest agrees to maintain the terrace in the same condition as found.\n'
                  '2. No damage to property, fixtures, or surroundings.\n'
                  '3. Noise levels must be kept within permissible limits.\n'
                  '4. All permitted activities as listed must be adhered to.\n'
                  '5. Overstay will be charged at 2× hourly rate.\n'
                  '6. Security deposit will be refunded within 48 hours post-inspection.\n'
                  '7. Gusto Meets is not liable for personal injury or loss of belongings.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _waiverChecked,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _waiverChecked = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to the terms and waiver above.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GustoButton(
              onPressed: _waiverChecked ? _pay : null,
              label: 'Pay ${CurrencyUtils.formatINR(_total)}',
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
