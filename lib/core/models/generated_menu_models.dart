class SavedMenuCollection {
  final String localId;
  final String title;
  final String healthGoal;
  final List<String> notes;
  final int days;
  final int mealsPerDay;
  final DateTime createdAt;
  final List<MenuDayPlan> menu;

  const SavedMenuCollection({
    required this.localId,
    required this.title,
    required this.healthGoal,
    required this.notes,
    required this.days,
    required this.mealsPerDay,
    required this.createdAt,
    required this.menu,
  });

  factory SavedMenuCollection.fromGeneratedResponse(Map<String, dynamic> json) {
    final now = DateTime.now();
    final healthGoal = (json['health_goal'] ?? 'Cân bằng').toString();

    return SavedMenuCollection(
      localId: now.microsecondsSinceEpoch.toString(),
      title: 'Thực đơn $healthGoal',
      healthGoal: healthGoal,
      notes: (json['notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      days: _parseInt(json['days'], fallback: 1),
      mealsPerDay: _parseInt(json['meals_per_day'], fallback: 3),
      createdAt: now,
      menu: (json['menu'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuDayPlan.fromJson)
          .toList(),
    );
  }

  factory SavedMenuCollection.fromJson(Map<String, dynamic> json) {
    return SavedMenuCollection(
      localId: (json['local_id'] ?? '').toString(),
      title: (json['title'] ?? 'Thực đơn AI').toString(),
      healthGoal: (json['health_goal'] ?? 'Cân bằng').toString(),
      notes: (json['notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      days: _parseInt(json['days'], fallback: 1),
      mealsPerDay: _parseInt(json['meals_per_day'], fallback: 3),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      menu: (json['menu'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuDayPlan.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'title': title,
      'health_goal': healthGoal,
      'notes': notes,
      'days': days,
      'meals_per_day': mealsPerDay,
      'created_at': createdAt.toIso8601String(),
      'menu': menu.map((day) => day.toJson()).toList(),
    };
  }
}

class MenuDayPlan {
  final int day;
  final List<MenuMealPlan> meals;

  const MenuDayPlan({required this.day, required this.meals});

  factory MenuDayPlan.fromJson(Map<String, dynamic> json) {
    return MenuDayPlan(
      day: _parseInt(json['day'], fallback: 1),
      meals: (json['meals'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MenuMealPlan.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'meals': meals.map((meal) => meal.toJson()).toList()};
  }
}

class MenuMealPlan {
  final String meal;
  final MenuDishPlan dish;

  const MenuMealPlan({required this.meal, required this.dish});

  factory MenuMealPlan.fromJson(Map<String, dynamic> json) {
    return MenuMealPlan(
      meal: (json['meal'] ?? 'Bữa ăn').toString(),
      dish: MenuDishPlan.fromJson(
        (json['dish'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'meal': meal, 'dish': dish.toJson()};
  }
}

class MenuDishPlan {
  final String dishId;
  final String dishName;
  final String? imageUrl;
  final double? calories;
  final String? cookingTime;
  final String? level;
  final String? servings;

  const MenuDishPlan({
    required this.dishId,
    required this.dishName,
    this.imageUrl,
    this.calories,
    this.cookingTime,
    this.level,
    this.servings,
  });

  factory MenuDishPlan.fromJson(Map<String, dynamic> json) {
    return MenuDishPlan(
      dishId: (json['dish_id'] ?? '').toString(),
      dishName: (json['dish_name'] ?? json['ten_mon_an'] ?? 'Món ăn')
          .toString(),
      imageUrl: json['image_url']?.toString(),
      calories: _parseDouble(json['calories']),
      cookingTime: json['cooking_time']?.toString(),
      level: json['level']?.toString(),
      servings: json['servings']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dish_id': dishId,
      'dish_name': dishName,
      'image_url': imageUrl,
      'calories': calories,
      'cooking_time': cookingTime,
      'level': level,
      'servings': servings,
    };
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}
