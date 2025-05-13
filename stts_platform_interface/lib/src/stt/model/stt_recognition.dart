/// Speech recognition representation.
class SttRecognition {
  SttRecognition(this.text, this.isFinal);

  /// The recognized text.
  final String text;

  /// [true], if final recognition. Otherwise, it's an interim result.
  final bool isFinal;
}
