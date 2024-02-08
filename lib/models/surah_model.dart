class Surah {
  final int number;
  final String name;
  final String translation;
  final String arabic;
  final String tempatTurun;

  Surah({
    required this.number,
    required this.name,
    required this.translation,
    required this.arabic,
    required this.tempatTurun,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['nomor'] ?? 0,
      name: json['namaLatin'] ?? 'Unknown',
      translation: json['arti'] ?? 'No Translation',
      arabic: json['nama'] ?? 'No Arabic Name',
      tempatTurun: json['tempatTurun'] ?? 'Unknown',
    );
  }
}
