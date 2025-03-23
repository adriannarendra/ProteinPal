import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:my_protein/model/recipe_model.dart';
import 'package:my_protein/network/gemini_services.dart';
import 'package:my_protein/screens/saved_recipes_screen.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (newValue.text.length < oldValue.text.length) {
      return _handleDeletion(oldValue, newValue);
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    String formattedText = _formatCurrency(cleanText);

    int offset = newValue.selection.end;
    int diff = formattedText.length - newValue.text.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: offset + diff),
    );
  }

  TextEditingValue _handleDeletion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formattedText = _formatCurrency(cleanText);

    int offset = newValue.selection.end;
    int diff = formattedText.length - newValue.text.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: offset + diff),
    );
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return 'Rp0';

    String text = value.split('').reversed.join();
    String result = '';

    for (int i = 0; i < text.length; i++) {
      if (i % 3 == 0 && i != 0) {
        result += '.';
      }
      result += text[i];
    }

    result = result.split('').reversed.join();

    result = result.replaceAll(RegExp(r'^0+(?=\d)'), '');

    if (result.isEmpty) return 'Rp0';

    return 'Rp$result';
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _proteinSourceController =
      TextEditingController();
  bool isLoading = false;
  String? errorMessage = "";
  Map<String, dynamic>? recipeData;

  final List<String> proteinSources = [
    'Chicken',
    'Eggs',
    'Beef',
    'Fish',
    'Greek yogurt',
    'Lentils',
    'Chickpeas',
    'Tofu',
    'Tempe',
    'Almonds',
    'Peanuts',
    'Peanut butter',
    'Oats',
    'Black beans',
  ];

  @override
  void initState() {
    super.initState();
    _proteinSourceController.text = proteinSources.first;
  }

  Future<void> generateRecipe() async {
    setState(() => isLoading = true);
    try {
      String getRawBudget() {
        String clean = _budgetController.text
            .replaceAll('Rp', '')
            .replaceAll('.', '');
        return clean.isEmpty ? '0' : clean;
      }

      final result = await GeminiServices.generateRecipe(
        getRawBudget(),
        _proteinController.text,
        _proteinSourceController.text,
      );

      if (result.containsKey('error')) {
        setState(() {
          errorMessage = result['error'];
          recipeData = null;
          isLoading = false;
        });
        return;
      }

      setState(() {
        recipeData = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to generate recipe\n$e";
        recipeData = null;
        isLoading = false;
      });
    }
  }

  Future<void> saveRecipe() async {
    if (recipeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada resep untuk disimpan!')),
      );
      return;
    }

    final recipe = RecipeModel(
      recipeName: recipeData!['recipe_name'] ?? 'Resep Tanpa Nama',
      ingredients: List<Map<String, dynamic>>.from(recipeData!['ingredients']),
      totalCost: recipeData!['total_cost'] ?? 'Rp0',
      totalProtein: recipeData!['total_protein'] ?? 0,
      instructions: List<String>.from(recipeData!['instructions']),
    );

    try {
      final recipeBox = Hive.box<RecipeModel>('recipes');
      await recipeBox.add(recipe);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resep berhasil disimpan!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan resep: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ProteinPal",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        elevation: 5,
        actions: [
          if (recipeData != null && !isLoading)
            IconButton(
              icon: Icon(Icons.save, color: Colors.white),
              onPressed: saveRecipe,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputSection(),
              const SizedBox(height: 24),
              _buildGenerateButton(),
              const SizedBox(height: 24),
              if (errorMessage!.isNotEmpty && !isLoading) _buildErrorCard(),
              if (isLoading) _buildLoadingShimmer(),
              if (recipeData != null && !isLoading) _buildRecipeCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SavedRecipesScreen()),
            ),
        child: const Icon(Icons.menu_book, color: Colors.white),
        backgroundColor: Colors.green[800],
        elevation: 4,
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            label: Text("Budget (IDR)", style: GoogleFonts.poppins()),
            hintText: "Contoh: Rp50.000",
            prefixIcon: const Icon(Icons.attach_money_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _proteinController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: Text("Target Protein (gram)", style: GoogleFonts.poppins()),
            hintText: "Contoh: 50",
            prefixIcon: const Icon(Icons.fitness_center),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField(
          value: _proteinSourceController.text,
          decoration: InputDecoration(
            label: Text("Sumber Protein Utama", style: GoogleFonts.poppins()),
            prefixIcon: const Icon(Icons.food_bank),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items:
              proteinSources.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(source, style: GoogleFonts.poppins()),
                );
              }).toList(),
          onChanged:
              (value) => setState(() {
                _proteinSourceController.text = value!;
              }),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: generateRecipe,
        icon:
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(
                  Icons.restaurant_menu,
                  size: 24,
                  color: Colors.white,
                ),
        label: Text(
          isLoading ? "Membuat Resep..." : "Buat Resep Sekarang",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[800]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Resep Anda",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.green[800], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipeData!['recipe_name'] ?? "Resep",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Bahan-bahan"),
                ...(recipeData!['ingredients'] as List<dynamic>).map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green[800]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${ingredient['name']} (${ingredient['quantity']})",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Harga: ${ingredient['price']} | Protein: ${ingredient['protein']}g",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTotalRow(
                  "Total Biaya",
                  recipeData!['total_cost'] ?? "Rp0",
                ),
                _buildTotalRow(
                  "Total Protein",
                  "${recipeData!['total_protein']}g",
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Cara Membuat"),
                ...(recipeData!['instructions'] as List<dynamic>).map(
                  (step) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "•",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.toString(),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: Colors.green[800], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
