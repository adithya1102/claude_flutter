import '../../core/errors/app_exception.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/supabase_booking_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseBookingSource _source;
  BookingRepositoryImpl(this._source);

  @override
  Future<bool> isSlotAvailable(
      String terraceId, DateTime start, DateTime end) async {
    try {
      return await _source.isSlotAvailable(terraceId, start, end);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<BookingEntity> createBooking(BookingEntity booking) async {
    try {
      return await _source.createBooking(booking);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<void> confirmBooking(
      String bookingId, String razorpayPaymentId) async {
    try {
      await _source.confirmBooking(bookingId, razorpayPaymentId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<void> checkInGuest(String bookingId) async {
    try {
      await _source.checkInGuest(bookingId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<BookingEntity> extendBooking(
      String bookingId, int additionalMinutes, double additionalCost) async {
    try {
      return await _source.extendBooking(
          bookingId, additionalMinutes, additionalCost);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<void> checkoutBooking(String bookingId) async {
    try {
      await _source.checkoutBooking(bookingId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<BookingEntity?> getBooking(String id) async {
    try {
      return await _source.getBooking(id);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<List<BookingEntity>> getGuestBookings(String guestId) async {
    try {
      return await _source.getGuestBookings(guestId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<List<BookingEntity>> getTodaysHostBookings(String hostId) async {
    try {
      return await _source.getTodaysHostBookings(hostId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }

  @override
  Future<List<BookingEntity>> getHostBookings(String hostId) async {
    try {
      return await _source.getHostBookings(hostId);
    } catch (e) {
      throw BookingException(e.toString());
    }
  }
}
