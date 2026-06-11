import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/terrace_entity.dart';
import '../../../domain/enums/booking_purpose.dart';
import '../../common/providers/supabase_provider.dart';
import '../../common/widgets/gusto_button.dart';
import '../../common/widgets/permission_badge.dart';

class TerraceDetailScreen extends ConsumerStatefulWidget {
  final String terraceId;
  final TerraceEntity? terrace;

  const TerraceDetailScreen({
    super.key,
    required this.terraceId,
    this.terrace,
  });

  @override
  ConsumerState<TerraceDetailScreen> createState() =>
      _TerraceDetailScreenState();
}

class _TerraceDetailScreenState extends ConsumerState<TerraceDetailScreen> {
  DateTime? _selectedDate;
  String? _startTime;
  String? _endTime;
  BookingPurpose? _selectedPurpose;
  int _guestCount = 2;
  bool? _slotAvailable;
  bool _checkingSlot = false;

  List<String> get _timeSlots {
    final slots = <String>[];
    for (int h = 6; h <= 23; h++) {
      final hour = h > 12 ? h - 12 : h;
      final suffix = h >= 12 ? 'PM' : 'AM';
      slots.add('$hour:00 $suffix');
      if (h < 23) slots.add('$hour:30 $suffix');
    }
    return slots;
  }

  DateTime? _parseTime(String? timeStr, DateTime? date) {
    if (timeStr == null || date == null) return null;
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  double get _totalHours {
    final start = _parseTime(_startTime, _selectedDate);
    final end = _parseTime(_endTime, _selectedDate);
    if (start == null || end == null || end.isBefore(start)) return 0;
    return end.difference(start).inMinutes / 60.0;
  }

  double _baseCost(TerraceEntity t) =>
      t.baseHourlyRate * _totalHours;

  double _purposePremium(TerraceEntity t) {
    if (_selectedPurpose == null) return 0;
    final multiplier = _selectedPurpose!.priceMultiplier;
    if (multiplier <= 1.0) return 0;
    return _baseCost(t) * (multiplier - 1.0);
  }

  double _platformFee(TerraceEntity t) =>
      (_baseCost(t) + _purposePremium(t)) * AppConstants.platformFeePercent;

  double _securityDeposit(TerraceEntity t) {
    if (t.permissions?.allowAlcohol == true &&
        _selectedPurpose != null) {
      return t.permissions!.alcoholDeposit;
    }
    return 0;
  }

  double _total(TerraceEntity t) =>
      _baseCost(t) + _purposePremium(t) + _platformFee(t) + _securityDeposit(t);

  Future<void> _checkSlot(TerraceEntity t) async {
    final start = _parseTime(_startTime, _selectedDate);
    final end = _parseTime(_endTime, _selectedDate);
    if (start == null || end == null) return;
    setState(() => _checkingSlot = true);
    try {
      final available = await ref
          .read(bookingRepoProvider)
          .isSlotAvailable(t.id, start, end);
      setState(() {
        _slotAvailable = available;
        _checkingSlot = false;
      });
    } catch (_) {
      setState(() => _checkingSlot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final terrace = widget.terrace;
    if (terrace == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: terrace.photos.isNotEmpty
                      ? PageView.builder(
                          itemCount: terrace.photos.length,
                          onPageChanged: (_) {},
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: terrace.photos[i],
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceVariant,
                            ),
                          ),
                        )
                      : Container(color: AppColors.surfaceVariant),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              terrace.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${CurrencyUtils.formatINR(terrace.baseHourlyRate)}/hr',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (terrace.area != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(terrace.area!,
                                  style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.people_outline,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Up to ${terrace.maxCapacity}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (terrace.permissions != null) ...[
                        const Text('What\'s allowed',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PermissionBadge(
                              label: 'Alcohol',
                              icon: Icons.local_bar,
                              allowed: terrace.permissions!.allowAlcohol,
                              color: AppColors.badgeAlcohol,
                            ),
                            PermissionBadge(
                              label: 'Smoking',
                              icon: Icons.smoking_rooms,
                              allowed: terrace.permissions!.allowSmoking,
                              color: AppColors.badgeSmoke,
                            ),
                            PermissionBadge(
                              label: 'Outside Food',
                              icon: Icons.restaurant,
                              allowed:
                                  terrace.permissions!.allowOutsideFood,
                              color: AppColors.badgeFood,
                            ),
                            PermissionBadge(
                              label: 'Music',
                              icon: Icons.music_note,
                              allowed:
                                  terrace.permissions!.allowLoudMusic,
                              color: AppColors.badgeMusic,
                            ),
                            PermissionBadge(
                              label: 'Couples',
                              icon: Icons.favorite,
                              allowed:
                                  terrace.permissions!.allowCouples,
                              color: AppColors.badgeCouples,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (terrace.description != null) ...[
                        const Text('About this space',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(terrace.description!,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Book this space',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary)),
                            const SizedBox(height: 12),
                            const Text('Select date',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 64,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 7,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final day = DateTime.now()
                                      .add(Duration(days: i));
                                  final selected = _selectedDate != null &&
                                      _selectedDate!.day == day.day &&
                                      _selectedDate!.month == day.month;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = day;
                                        _slotAvailable = null;
                                      });
                                      if (_startTime != null &&
                                          _endTime != null) {
                                        _checkSlot(terrace);
                                      }
                                    },
                                    child: Container(
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primary
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
                                                [day.weekday - 1],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: selected
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            '${day.day}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: selected
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('From',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      DropdownButton<String>(
                                        value: _startTime,
                                        isExpanded: true,
                                        hint: const Text('Start'),
                                        items: _timeSlots
                                            .map((t) => DropdownMenuItem(
                                                value: t, child: Text(t)))
                                            .toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            _startTime = v;
                                            _slotAvailable = null;
                                          });
                                          if (_endTime != null &&
                                              _selectedDate != null) {
                                            _checkSlot(terrace);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('To',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      DropdownButton<String>(
                                        value: _endTime,
                                        isExpanded: true,
                                        hint: const Text('End'),
                                        items: _timeSlots
                                            .map((t) => DropdownMenuItem(
                                                value: t, child: Text(t)))
                                            .toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            _endTime = v;
                                            _slotAvailable = null;
                                          });
                                          if (_startTime != null &&
                                              _selectedDate != null) {
                                            _checkSlot(terrace);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_totalHours > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Duration: ${_totalHours.toStringAsFixed(1)} hours',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (terrace.permissions?.allowedPurposes
                                    .isNotEmpty ==
                                true) ...[
                              const Text('Purpose',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: terrace
                                    .permissions!.allowedPurposes
                                    .map((p) => GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedPurpose = p),
                                          child: Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 10,
                                                vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _selectedPurpose == p
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                              border: Border.all(
                                                color:
                                                    _selectedPurpose == p
                                                        ? AppColors.primary
                                                        : AppColors.border,
                                              ),
                                            ),
                                            child: Text(
                                              '${p.emoji} ${p.displayName}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    _selectedPurpose == p
                                                        ? Colors.white
                                                        : AppColors
                                                            .textPrimary,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                const Text('Guests:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: _guestCount > 1
                                      ? () => setState(
                                          () => _guestCount--)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: AppColors.primary,
                                ),
                                Text('$_guestCount',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: _guestCount <
                                          terrace.maxCapacity
                                      ? () => setState(
                                          () => _guestCount++)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            if (_totalHours > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _priceRow(
                                        'Base (${CurrencyUtils.formatINR(terrace.baseHourlyRate)} × ${_totalHours.toStringAsFixed(1)}h)',
                                        _baseCost(terrace)),
                                    if (_purposePremium(terrace) > 0)
                                      _priceRow(
                                          'Purpose premium',
                                          _purposePremium(terrace)),
                                    _priceRow(
                                        'Platform fee (15%)',
                                        _platformFee(terrace)),
                                    if (_securityDeposit(terrace) > 0)
                                      _priceRow(
                                          'Security deposit',
                                          _securityDeposit(terrace)),
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Text('Total',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        const Spacer(),
                                        Text(
                                          CurrencyUtils.formatINR(
                                              _total(terrace)),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_checkingSlot) ...[
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('Checking availability…'),
                                ],
                              ),
                            ] else if (_slotAvailable != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _slotAvailable!
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _slotAvailable!
                                        ? AppColors.primary
                                        : AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _slotAvailable!
                                        ? 'Slot available'
                                        : 'Slot taken, choose another time',
                                    style: TextStyle(
                                      color: _slotAvailable!
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_totalHours > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.formatINR(_total(terrace)),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text('total',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GustoButton(
                      onPressed: _canBook(terrace)
                          ? () => _navigateToBook(context, ref, terrace)
                          : null,
                      label: 'Book Now',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canBook(TerraceEntity t) =>
      _selectedDate != null &&
      _startTime != null &&
      _endTime != null &&
      _totalHours > 0 &&
      (_slotAvailable ?? false);

  void _navigateToBook(
      BuildContext context, WidgetRef ref, TerraceEntity t) {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user != null && !user.kycVerified) {
      context.go('/kyc');
      return;
    }
    final start = _parseTime(_startTime, _selectedDate)!;
    final end = _parseTime(_endTime, _selectedDate)!;
    context.go(
      '/explore/${t.id}/book',
      extra: {
        'terrace': t,
        'startTime': start,
        'endTime': end,
        'purpose': _selectedPurpose,
        'guestCount': _guestCount,
        'totalHours': _totalHours,
        'baseCost': _baseCost(t),
        'purposePremium': _purposePremium(t),
        'platformFee': _platformFee(t),
        'securityDeposit': _securityDeposit(t),
        'total': _total(t),
      },
    );
  }

  Widget _priceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(CurrencyUtils.formatINR(amount),
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
