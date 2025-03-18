import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiServices {
  static const String apiKey = 'AIzaSyDXGcb28Uf3n55GGiSz8vVK_HlwFluh1OA';

  static Future<Map<String, dynamic>> generateSchedule(
    List<Map<String, dynamic>> tasks,
  ) async {
    final prompt = _buildPrompt(tasks);

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
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
            '\'You are a student creating a realistic daily schedule. Consider task priority, duration, breaks, and energy levels throughout the day. Ensure tasks are balanced and practical. Provide output in JSON format with "pagi", "siang", and "malam" sections. Each task should have "task" and "time" fields. Always include a schedule recommendation section titled "saran". add more emoticon and Do not include any additional text outside the JSON structure.\'\n',
          ),
        ]),
        Content.model([
          TextPart(
            '```json\n{\n  "pagi": [\n    {\n      "task": "Wake up, hydrate, light stretching",\n      "time": "7:00 AM - 7:30 AM"\n    },\n    {\n      "task": "Breakfast and review daily schedule",\n      "time": "7:30 AM - 8:00 AM"\n    },\n    {\n      "task": "Focused study session (Math/Science)",\n      "time": "8:00 AM - 10:00 AM"\n    },\n    {\n      "task": "Short break: Walk, listen to music 🎧",\n      "time": "10:00 AM - 10:15 AM"\n    },\n    {\n      "task": "Review study notes and prepare for the day\'s class/activities",\n      "time": "10:15 AM - 11:00 AM"\n    },\n    {\n      "task": "Attend classes/meetings",\n      "time": "11:00 AM - 12:00 PM"\n    }\n  ],\n  "siang": [\n    {\n      "task": "Lunch",\n      "time": "12:00 PM - 12:30 PM"\n    },\n    {\n      "task": "Attend classes/meetings/Lab work",\n      "time": "12:30 PM - 2:30 PM"\n    },\n    {\n      "task": "Break: Walk in nature/ Get some Sunshine ☀️",\n      "time": "2:30 PM - 2:45 PM"\n    },\n    {\n      "task": "Work on assignments/projects (Less demanding)",\n      "time": "2:45 PM - 4:30 PM"\n    },\n    {\n      "task": "Gym/Excercise",\n      "time": "4:30 PM - 5:30 PM"\n    }\n\n  ],\n  "malam": [\n    {\n      "task": "Dinner",\n      "time": "5:30 PM - 6:00 PM"\n    },\n    {\n      "task": "Relaxation: Hobby/Social time",\n      "time": "6:00 PM - 7:00 PM"\n    },\n    {\n      "task": "Review notes or readings (lighter topics)",\n      "time": "7:00 PM - 8:00 PM"\n    },\n    {\n      "task": "Plan for the next day",\n      "time": "8:00 PM - 8:30 PM"\n    },\n    {\n      "task": "Personal care and prepare for bed",\n      "time": "8:30 PM - 9:30 PM"\n    },\n    {\n      "task": "Sleep 😴",\n      "time": "9:30 PM"\n    }\n  ],\n  "saran": [\n    {\n      "task": "Prioritize tasks based on deadlines and importance.",\n      "recommendation": "Use a planner or to-do list to track your tasks."\n    },\n    {\n      "task": "Take regular breaks to avoid burnout.",\n      "recommendation": "Even short breaks can improve focus and productivity."\n    },\n    {\n      "task": "Adjust the schedule based on your energy levels.",\n      "recommendation": "Schedule more demanding tasks for when you are most alert."\n    },\n    {\n      "task": "Ensure a balance between academic work and personal time.",\n      "recommendation": "Allocate time for hobbies, socializing, and relaxation."\n    },\n    {\n      "task": "Stay hydrated and eat healthy meals to maintain energy levels.",\n      "recommendation": "Avoid sugary snacks and drinks."\n    },\n     {\n      "task": "Keep a journal to track progress, insights and feeling. ",\n      "recommendation": "This will help with self awareness and improvements"\n    }\n  ]\n}\n```',
          ),
        ]),
      ],
    );
    final message = prompt;
    final content = Content.text(message);
    try {
      final response = await chat.sendMessage(content);

      final responseText =
          (response.candidates.first.content.parts.first as TextPart).text;

      if (responseText.isEmpty) {
        return {"error": "Failed to generate schedule"};
      }

      // JSON Pattern
      RegExp jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);

      if (match != null) {
        return jsonDecode(match.group(0)!);
      }

      return jsonDecode(responseText);
    } catch (e) {
      return {"error": "Failed to generate schedule\n$e"};
    }
  }

  static String _buildPrompt(List<Map<String, dynamic>> tasks) {
    String tasklist = tasks
        .map(
          (task) =>
              "-${task['task']} (Prioritas: ${task['priority']}, Durasi: ${task['duration']}, Deadline: ${task['deadline']})",
        )
        .join("\n");

    return "Buatkan jadwal harian yang optimal dari list tugas berikut: \n$tasklist\n. Susun jadwal dari pagi hingga malam hari dengan efisien dan berikan output dalam bentuk JSON.";
  }
}
