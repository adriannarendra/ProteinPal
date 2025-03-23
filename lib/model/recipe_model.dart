import 'package:hive/hive.dart';

part 'recipe_model.g.dart';

@HiveType(typeId: 0)
class RecipeModel {
  @HiveField(0)
  final String recipeName;

  @HiveField(1)
  final List<Map<String, dynamic>> ingredients;

  @HiveField(2)
  final String totalCost;

  @HiveField(3)
  final double totalProtein; 

  @HiveField(4)
  final List<String> instructions;

  RecipeModel({
    required this.recipeName,
    required this.ingredients,
    required this.totalCost,
    required this.totalProtein, 
    required this.instructions,
  });
}
