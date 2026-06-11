sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class BookingException extends AppException {
  const BookingException(super.message);
}

class PaymentException extends AppException {
  const PaymentException(super.message);
}

class KycException extends AppException {
  const KycException(super.message);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}
