class Note {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final bool isSynced;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] as String,
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    bool? isSynced,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
