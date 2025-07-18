class Tag {
  final int id;
  final String name;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final TagPivot? pivot;

  Tag({
    required this.id,
    required this.name,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pivot: json['pivot'] != null ? TagPivot.fromJson(json['pivot']) : null,
    );
  }
}

class TagPivot {
  final int taskId;
  final int tagId;

  TagPivot({required this.taskId, required this.tagId});

  factory TagPivot.fromJson(Map<String, dynamic> json) {
    return TagPivot(
      taskId: json['task_id'],
      tagId: json['tag_id'],
    );
  }
} 