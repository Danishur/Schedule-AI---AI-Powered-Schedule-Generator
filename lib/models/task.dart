import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String name;
  int duration; // in minutes
  String priority; // 'high', 'medium', 'low'
  String? deadline;
  String? notes;
  bool isCompleted;
  DateTime createdAt;

  Task({
    String? id,
    required this.name,
    required this.duration,
    required this.priority,
    this.deadline,
    this.notes,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? name,
    int? duration,
    String? priority,
    String? deadline,
    String? notes,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duration': duration,
        'priority': priority,
        'deadline': deadline,
        'notes': notes,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        name: json['name'],
        duration: json['duration'],
        priority: json['priority'],
        deadline: json['deadline'],
        notes: json['notes'],
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );

  String get priorityLabel {
    switch (priority) {
      case 'high': return 'High';
      case 'medium': return 'Medium';
      case 'low': return 'Low';
      default: return priority;
    }
  }

  String get durationLabel {
    if (duration < 60) return '${duration}m';
    final h = duration ~/ 60;
    final m = duration % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
