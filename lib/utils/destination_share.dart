const destinationSharePrefix =
    '\u{1f4cd} [\u{0110}\u{1ecb}a \u{0111}i\u{1ec3}m] ';

String? destinationNameFromShareMessage(String body) {
  for (final line in body.split('\n')) {
    if (!line.startsWith(destinationSharePrefix)) continue;
    final destinationName = line.substring(destinationSharePrefix.length).trim();
    return destinationName.isEmpty ? null : destinationName;
  }
  return null;
}