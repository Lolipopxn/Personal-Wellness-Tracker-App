class Achievement {
  final String id;
  final String userId;
  final String type;
  final String name;
  final String description;
  final int target;
  final int current;
  final bool achieved;
  final DateTime? achievedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.target,
    required this.current,
    required this.achieved,
    this.achievedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      name: json['name'],
      description: json['description'],
      target: json['target'],
      current: json['current'],
      achieved: json['achieved'],
      achievedAt: json['achieved_at'] != null 
          ? DateTime.parse(json['achieved_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'name': name,
      'description': description,
      'target': target,
      'current': current,
      'achieved': achieved,
      'achieved_at': achievedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? userId,
    String? type,
    String? name,
    String? description,
    int? target,
    int? current,
    bool? achieved,
    DateTime? achievedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      target: target ?? this.target,
      current: current ?? this.current,
      achieved: achieved ?? this.achieved,
      achievedAt: achievedAt ?? this.achievedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Achievement types enum
enum AchievementType {
  firstRecord('first_record'),
  mealLogging('meal_logging'),
  activityLogging('activity_logging'),
  goalAchievement('goal_achievement'),
  mealPlanning('meal_planning'),
  exerciseLogging('exercise_logging'),
  streakDays('streak_days'),
  waterIntake('water_intake');

  const AchievementType(this.value);
  final String value;
}
