import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<bool> isSlotAvailable(String terraceId, DateTime start, DateTime end);
  Future<BookingEntity> createBooking(BookingEntity booking);
  Future<void> confirmBooking(String bookingId, String razorpayPaymentId);
  Future<void> checkInGuest(String bookingId);
  Future<BookingEntity> extendBooking(
      String bookingId, int additionalMinutes, double additionalCost);
  Future<void> checkoutBooking(String bookingId);
  Future<BookingEntity?> getBooking(String id);
  Future<List<BookingEntity>> getGuestBookings(String guestId);
  Future<List<BookingEntity>> getTodaysHostBookings(String hostId);
  Future<List<BookingEntity>> getHostBookings(String hostId);
}
