/// Ellipsis form of a long `0x…` address for list tiles, subtitles, snackbars.
String shortenWalletAddress(
  String? address, {
  int prefixLen = 8,
  int suffixLen = 6,
}) {
  if (address == null || address.isEmpty) return '';
  final a = address.trim();
  if (a.length <= prefixLen + suffixLen + 3) return a;
  return '${a.substring(0, prefixLen)}...${a.substring(a.length - suffixLen)}';
}
