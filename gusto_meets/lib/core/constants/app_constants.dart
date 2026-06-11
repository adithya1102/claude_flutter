class AppConstants {
  AppConstants._();

  static const double platformFeePercent    = 0.15;
  static const double overstayMultiplier    = 2.0;
  static const int    bookingBufferMinutes  = 30;
  static const int    paymentTimeoutMinutes = 15;
  static const int    tMinus15AlertMinutes  = 15;
  static const int    maxExtensions         = 3;
  static const String defaultCity          = 'Chennai';

  static const List<String> areas = [
    'All', 'Velachery', 'OMR', 'Perungudi', 'Sholinganallur', 'Adyar', 'Anna Nagar',
  ];
}
