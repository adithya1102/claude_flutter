enum BookingPurpose {
  chillout('CHILLOUT'),
  dineOut('DINE_OUT'),
  movieNight('MOVIE_NIGHT'),
  party('PARTY'),
  boardGames('BOARD_GAMES'),
  studyGroup('STUDY_GROUP');

  const BookingPurpose(this.dbValue);
  final String dbValue;

  static BookingPurpose fromDb(String v) => BookingPurpose.values
      .firstWhere((e) => e.dbValue == v, orElse: () => BookingPurpose.chillout);

  String get displayName => switch (this) {
        BookingPurpose.chillout => 'Chillout',
        BookingPurpose.dineOut => 'Dine Out',
        BookingPurpose.movieNight => 'Movie Night',
        BookingPurpose.party => 'Party',
        BookingPurpose.boardGames => 'Board Games',
        BookingPurpose.studyGroup => 'Study Group',
      };

  String get emoji => switch (this) {
        BookingPurpose.chillout => '🛋️',
        BookingPurpose.dineOut => '🍽️',
        BookingPurpose.movieNight => '🎬',
        BookingPurpose.party => '🎉',
        BookingPurpose.boardGames => '🎲',
        BookingPurpose.studyGroup => '📚',
      };

  double get priceMultiplier => this == BookingPurpose.party ? 1.30 : 1.00;
}
