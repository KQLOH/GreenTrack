class GreenJournalEntry {
  final int? id;
  final String title;
  final String category;
  final String note;
  final int ecoPoints;
  final String entryDate;
  final String createdAt;

  GreenJournalEntry({
    this.id,
    required this.title,
    required this.category,
    required this.note,
    required this.ecoPoints,
    required this.entryDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'note': note,
      'eco_points': ecoPoints,
      'entry_date': entryDate,
      'created_at': createdAt,
    };
  }

  factory GreenJournalEntry.fromMap(Map<String, dynamic> map) {
    return GreenJournalEntry(
      id: map['id'] as int?,
      title: (map['title'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      ecoPoints: (map['eco_points'] as num?)?.toInt() ?? 0,
      entryDate: (map['entry_date'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
    );
  }

  GreenJournalEntry copyWith({
    int? id,
    String? title,
    String? category,
    String? note,
    int? ecoPoints,
    String? entryDate,
    String? createdAt,
  }) {
    return GreenJournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}