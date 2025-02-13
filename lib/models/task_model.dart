class TaskModel {
  String? id;
  String title;
  String description;
  DateTime? deadline;
  bool isCompleted;
  List<SubTask> subTasks;
  DateTime createdAt;
  DateTime? completedAt;

  TaskModel({
    this.id,
    required this.title,
    this.description = '',
    this.deadline,
    this.isCompleted = false,
    List<SubTask>? subTasks,
  })  : subTasks = subTasks ?? [],
        createdAt = DateTime.now();

  double get progress {
    if (subTasks.isEmpty) return 1.0;
    int completedCount = subTasks.where((st) => st.isCompleted).length;
    return completedCount / subTasks.length;
  }

  bool get isOverdue =>
      deadline != null && deadline!.isBefore(DateTime.now()) && !isCompleted;

  factory TaskModel.fromJson(Map<String, dynamic> data) {
    return TaskModel(
      id: data['id'],
      title: data['title'],
      description: data['description'] ?? '',
      deadline: _parseDeadline(data['deadline']),
      isCompleted: data['isCompleted'] ?? false,
      subTasks: (data['subtask'] as List?)
              ?.map((st) => SubTask.fromJson(st))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
      'subtask': subTasks.map((st) => st.toJson()).toList(),
    };
  }

  static DateTime? _parseDeadline(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class SubTask {
  String? id;
  String title;
  bool isCompleted;

  SubTask({
    required this.title,
    this.isCompleted = false,
    String? id,
  });

  factory SubTask.fromJson(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'],
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}
