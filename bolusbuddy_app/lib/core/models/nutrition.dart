class NutrientRange {
  const NutrientRange({
    required this.value,
    required this.min,
    required this.max,
  });

  final double value;
  final double min;
  final double max;

  NutrientRange scale(double factor) {
    return NutrientRange(
      value: value * factor,
      min: min * factor,
      max: max * factor,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'min': min,
        'max': max,
      };

  static NutrientRange fromJson(Map<String, dynamic> json) {
    return NutrientRange(
      value: (json['value'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }
}
