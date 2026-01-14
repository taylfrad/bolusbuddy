import 'nutrition.dart';

class MealItemEstimate {
  const MealItemEstimate({
    required this.id,
    required this.name,
    required this.grams,
    required this.unit,
    required this.confidence,
    required this.carbs,
    required this.netCarbs,
    required this.protein,
    required this.fat,
    required this.calories,
  });

  final String id;
  final String name;
  final double grams;
  final String unit;
  final double confidence;
  final NutrientRange carbs;
  final NutrientRange netCarbs;
  final NutrientRange protein;
  final NutrientRange fat;
  final NutrientRange calories;

  MealItemEstimate copyWith({
    double? grams,
    String? unit,
    NutrientRange? carbs,
    NutrientRange? netCarbs,
    NutrientRange? protein,
    NutrientRange? fat,
    NutrientRange? calories,
    double? confidence,
  }) {
    return MealItemEstimate(
      id: id,
      name: name,
      grams: grams ?? this.grams,
      unit: unit ?? this.unit,
      confidence: confidence ?? this.confidence,
      carbs: carbs ?? this.carbs,
      netCarbs: netCarbs ?? this.netCarbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grams': grams,
        'unit': unit,
        'confidence': confidence,
        'carbs': carbs.toJson(),
        'netCarbs': netCarbs.toJson(),
        'protein': protein.toJson(),
        'fat': fat.toJson(),
        'calories': calories.toJson(),
      };

  static MealItemEstimate fromJson(Map<String, dynamic> json) {
    return MealItemEstimate(
      id: json['id'] as String,
      name: json['name'] as String,
      grams: (json['grams'] as num).toDouble(),
      unit: json['unit'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      carbs: NutrientRange.fromJson(json['carbs'] as Map<String, dynamic>),
      netCarbs: NutrientRange.fromJson(json['netCarbs'] as Map<String, dynamic>),
      protein: NutrientRange.fromJson(json['protein'] as Map<String, dynamic>),
      fat: NutrientRange.fromJson(json['fat'] as Map<String, dynamic>),
      calories: NutrientRange.fromJson(json['calories'] as Map<String, dynamic>),
    );
  }
}

class MealEstimate {
  const MealEstimate({
    required this.imageHash,
    required this.items,
    required this.totalCarbs,
    required this.totalNetCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCalories,
    required this.confidence,
    required this.mode,
  });

  final String imageHash;
  final List<MealItemEstimate> items;
  final NutrientRange totalCarbs;
  final NutrientRange totalNetCarbs;
  final NutrientRange totalProtein;
  final NutrientRange totalFat;
  final NutrientRange totalCalories;
  final double confidence;
  final String mode;

  Map<String, dynamic> toJson() => {
        'imageHash': imageHash,
        'items': items.map((item) => item.toJson()).toList(),
        'totalCarbs': totalCarbs.toJson(),
        'totalNetCarbs': totalNetCarbs.toJson(),
        'totalProtein': totalProtein.toJson(),
        'totalFat': totalFat.toJson(),
        'totalCalories': totalCalories.toJson(),
        'confidence': confidence,
        'mode': mode,
      };

  static MealEstimate fromJson(Map<String, dynamic> json) {
    return MealEstimate(
      imageHash: json['imageHash'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => MealItemEstimate.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCarbs:
          NutrientRange.fromJson(json['totalCarbs'] as Map<String, dynamic>),
      totalNetCarbs:
          NutrientRange.fromJson(json['totalNetCarbs'] as Map<String, dynamic>),
      totalProtein:
          NutrientRange.fromJson(json['totalProtein'] as Map<String, dynamic>),
      totalFat:
          NutrientRange.fromJson(json['totalFat'] as Map<String, dynamic>),
      totalCalories:
          NutrientRange.fromJson(json['totalCalories'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      mode: json['mode'] as String,
    );
  }
}
