import 'package:flutter_test/flutter_test.dart';
import 'package:dngo/core/models/generated_menu_models.dart';

void main() {
  test('parses generated menu response into a saved plan', () {
    final plan = SavedMenuCollection.fromGeneratedResponse({
      'health_goal': 'Cân bằng',
      'notes': ['Món chay'],
      'days': 2,
      'meals_per_day': 3,
      'menu': [
        {
          'day': 1,
          'meals': [
            {
              'meal': 'Bữa sáng',
              'dish': {
                'dish_id': 'MA001',
                'dish_name': 'Phở chay',
                'image_url': 'https://example.com/pho.jpg',
                'calories': 320,
                'cooking_time': '20 phút',
                'level': 'Dễ',
              },
            },
          ],
        },
      ],
    });

    expect(plan.healthGoal, 'Cân bằng');
    expect(plan.days, 2);
    expect(plan.menu.first.meals.first.dish.dishId, 'MA001');
    expect(plan.menu.first.meals.first.dish.dishName, 'Phở chay');
  });
}
