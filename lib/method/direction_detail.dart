

class DirectionDetails {
  String? distanceTextString;
  String? durationTextString;
  int? distanceValuableDigits;   // Changed to int
  int? durationValuableDigits;   // Changed to int
  String? encodedPoints;

  DirectionDetails({
    this.distanceTextString,
    this.durationTextString,
    this.distanceValuableDigits,
    this.durationValuableDigits,
    this.encodedPoints,
  });
}
