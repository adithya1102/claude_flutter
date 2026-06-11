import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking_entity.dart';
import '../../core/constants/supabase_tables.dart';

class SupabaseBookingSource {
  final SupabaseClient _client;
  SupabaseBookingSource(this._client);

  Future<bool> isSlotAvailable(
      String terraceId, DateTime start, DateTime end) async {
    final bufferStart = start.subtract(const Duration(minutes: 30));
    final bufferEnd = end.add(const Duration(minutes: 30));
    final result = await _client
        .from(SupabaseTables.bookings)
        .select('id')
        .eq('terrace_id', terraceId)
        .inFilter('status', ['CONFIRMED', 'ACTIVE', 'EXTENDED', 'OVERSTAYED'])
        .lt('start_time', bufferEnd.toUtc().toIso8601String())
        .gt('end_time', bufferStart.toUtc().toIso8601String());
    return (result as List).isEmpty;
  }

  Future<BookingEntity> createBooking(BookingEntity booking) async {
    final map = booking.toMap()..remove('id');
    final data = await _client
        .from(SupabaseTables.bookings)
        .insert(map)
        .select()
        .single();
    return BookingEntity.fromMap(data);
  }

  Future<void> confirmBooking(
      String bookingId, String razorpayPaymentId) async {
    await _client.from(SupabaseTables.bookings).update({
      'status': 'CONFIRMED',
      'razorpay_payment_id': razorpayPaymentId,
    }).eq('id', bookingId);
  }

  Future<void> checkInGuest(String bookingId) async {
    await _client.from(SupabaseTables.bookings).update({
      'host_checked_in': true,
      'host_checked_in_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'ACTIVE',
    }).eq('id', bookingId);
  }

  Future<BookingEntity> extendBooking(
      String bookingId, int additionalMinutes, double additionalCost) async {
    final current = await getBooking(bookingId);
    if (current == null) throw Exception('Booking not found');
    final newEnd =
        current.endTime.add(Duration(minutes: additionalMinutes));
    final data = await _client
        .from(SupabaseTables.bookings)
        .update({
          'end_time': newEnd.toUtc().toIso8601String(),
          'extensions_count': current.extensionsCount + 1,
          'status': 'EXTENDED',
          'total_time_cost': current.totalTimeCost + additionalCost,
        })
        .eq('id', bookingId)
        .select()
        .single();
    return BookingEntity.fromMap(data);
  }

  Future<void> checkoutBooking(String bookingId) async {
    await _client.from(SupabaseTables.bookings).update({
      'actual_checkout_time': DateTime.now().toUtc().toIso8601String(),
      'status': 'COMPLETED',
    }).eq('id', bookingId);
  }

  Future<BookingEntity?> getBooking(String id) async {
    final data = await _client
        .from(SupabaseTables.bookings)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return BookingEntity.fromMap(data);
  }

  Future<List<BookingEntity>> getGuestBookings(String guestId) async {
    final result = await _client
        .from(SupabaseTables.bookings)
        .select()
        .eq('guest_id', guestId)
        .order('created_at', ascending: false);
    return (result as List<dynamic>)
        .map((m) => BookingEntity.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingEntity>> getTodaysHostBookings(String hostId) async {
    final terraces = await _client
        .from(SupabaseTables.terraces)
        .select('id')
        .eq('host_id', hostId);
    final ids = (terraces as List<dynamic>)
        .map((t) => (t as Map<String, dynamic>)['id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _client
        .from(SupabaseTables.bookings)
        .select()
        .inFilter('terrace_id', ids)
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lt('start_time', endOfDay.toUtc().toIso8601String())
        .order('start_time');
    return (result as List<dynamic>)
        .map((m) => BookingEntity.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingEntity>> getHostBookings(String hostId) async {
    final terraces = await _client
        .from(SupabaseTables.terraces)
        .select('id')
        .eq('host_id', hostId);
    final ids = (terraces as List<dynamic>)
        .map((t) => (t as Map<String, dynamic>)['id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final result = await _client
        .from(SupabaseTables.bookings)
        .select()
        .inFilter('terrace_id', ids)
        .order('start_time', ascending: false);
    return (result as List<dynamic>)
        .map((m) => BookingEntity.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
