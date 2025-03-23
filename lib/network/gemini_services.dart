import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiServices {
  static const String apiKey = 'AIzaSyDXGcb28Uf3n55GGiSz8vVK_HlwFluh1OA';

  static Future<Map<String, dynamic>> generateRecipe(
    String budget,
    String protein,
    String proteinSource,
  ) async {
    final prompt = _buildPrompt(budget, protein, proteinSource);

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat(
      history: [
        Content.multi([
          TextPart(
            '''Anda adalah seorang ahli gizi dan perencana makanan hemat budget. Buat resep yang memenuhi atau melebihi kebutuhan protein pengguna sambil tetap berada dalam budget. 
  Selalu sertakan:
  - Daftar bahan dengan jumlah, harga (dalam IDR), dan kandungan protein
  - Total biaya resep dan total protein (HARUS MEMENUHI atau MELEBIHI protein yang diminta)
  - Langkah-langkah memasak
  - Gunakan harga dan bahan lokal Indonesia
  Format respons dalam JSON. Jangan gunakan format markdown.''',
          ),
        ]),
        Content.model([
          TextPart('''{
              "recipe_name": "Ayam Bakar Madu",
              "ingredients": [
                {
                  "name": "Dada Ayam",
                  "quantity": "300g",
                  "price": "Rp15.000",
                  "protein": 62
                },
                {
                  "name": "Madu",
                  "quantity": "2 sdm",
                  "price": "Rp2.000",
                  "protein": 0
                }
              ],
              "total_cost": "Rp17.500",
              "total_protein": 68,
              "instructions": [
                "Marinasi ayam dengan bumbu selama 30 menit",
                "Panggang di oven 180°C selama 25 menit"
              ]
            }'''),
        ]),
      ],
    );

    try {
      final response = await chat.sendMessage(Content.text(prompt));
      final responseText =
          (response.candidates.first.content.parts.first as TextPart).text;

      if (responseText.isEmpty) {
        return {"error": "Failed to generate recipe"};
      }

      // Extract JSON from response
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);

      if (match != null) {
        return jsonDecode(match.group(0)!);
      }

      return {"error": "Invalid response format"};
    } catch (e) {
      return {"error": "Failed to generate recipe\n$e"};
    }
  }

  static String _buildPrompt(
    String budget,
    String protein,
    String proteinSource,
  ) {
    return '''Buatkan resep makanan dengan ketentuan:
- Budget maksimal: Rp$budget
- Total protein minimal: $protein gram (tidak boleh kurang dari ini)
- Sumber protein utama: $proteinSource
- Tampilkan harga per bahan dalam IDR
- Hitung total biaya dan total protein
- Berikan instruksi memasak yang jelas''';
  }
}
