import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:schedule_generator_with_gemini/network/gemini_services.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String? _priority;
  bool isLoading = false;
  String? errorMessage = "";

  List<Map<String, dynamic>> morningTasks = [];
  List<Map<String, dynamic>> afternoonTasks = [];
  List<Map<String, dynamic>> eveningTasks = [];
  List<String> suggestions = [];

  void _addTask() {
    if (_taskController.text.isNotEmpty &&
        _durationController.text.isNotEmpty &&
        _priority != null) {
      setState(() {
        _tasks.add({
          "task": _taskController.text,
          "duration": "${_durationController.text} Menit",
          "priority": _priority,
          "deadline": "",
        });

        _taskController.clear();
        _durationController.clear();

        print(_tasks);
      });
    }
  }

  Future<void> generateSchedule() async {
    setState(() => isLoading = true);
    try {
      final result = await GeminiServices.generateSchedule(_tasks);
      if (result.containsKey('error')) {
        setState(() {
          errorMessage = result['error'];
          morningTasks.clear();
          afternoonTasks.clear();
          eveningTasks.clear();
          suggestions.clear();
          isLoading = false;
        });
        return;
      }
      setState(() {
        morningTasks = List<Map<String, dynamic>>.from(result['pagi'] ?? []);
        afternoonTasks = List<Map<String, dynamic>>.from(result['siang'] ?? []);
        eveningTasks = List<Map<String, dynamic>>.from(result['malam'] ?? []);
        suggestions =
            (result['saran'] as List<dynamic>)
                .map((item) => item['task'] as String)
                .toList();
        isLoading = false;
      });
      print(result);
    } catch (e) {
      setState(() {
        errorMessage = "Failed to generate schedule\n$e";
        morningTasks.clear();
        afternoonTasks.clear();
        eveningTasks.clear();
        suggestions.clear();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Schedule Generator"), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  label: Text("Nama Tugas"),
                  hintText: "Nama Tugas",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text("Durasi (Menit)"),
                  hintText: "Durasi (Menit)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      hint: Text("Pilih Prioritas"),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items:
                          ["Tinggi", "Sedang", "Rendah"]
                              .map(
                                (priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (String? priority) => setState(() {
                            _priority = priority;
                          }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addTask,
                label: Text(
                  "Tambahkan Tugas",
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_tasks.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      var task = _tasks[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            FontAwesomeIcons.listCheck,
                            color: Colors.blueAccent,
                          ),
                          title: Text(task["task"]),
                          subtitle: Text(
                            "Durasi: ${task["duration"]} | prioritas: ${task["priority"]}",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),

                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index);
                              });
                            },
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 10),
              if (_tasks.isNotEmpty && _tasks.length > 1)
                ElevatedButton.icon(
                  onPressed: generateSchedule,
                  label: Text(
                    isLoading ? "Generating ..." : "Generate Schedule",
                    style: TextStyle(color: Colors.white),
                  ),
                  icon:
                      isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: Colors.white,
                            ),
                          )
                          : Icon(Icons.schedule, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (errorMessage!.isNotEmpty && !isLoading)
                Card(
                  color: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 10),
              if (isLoading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(height: 10, width: 300),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(height: 40, width: 200),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(height: 60, width: 400),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(height: 10, width: 800),
                      ),
                    ),
                  ],
                ),

              if (!isLoading &&
                  errorMessage!.isEmpty &&
                  (morningTasks.isNotEmpty ||
                      afternoonTasks.isNotEmpty ||
                      eveningTasks.isNotEmpty))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.blueAccent.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pagi",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (morningTasks.isEmpty)
                              Text(
                                "Tidak ada tugas",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ...morningTasks.map(
                              (morning) => ListTile(
                                title: Text(
                                  morning['task'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  morning["time"],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      color: const Color.fromARGB(255, 255, 115, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Siang",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (afternoonTasks.isEmpty)
                              Text(
                                "Tidak ada tugas",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ...afternoonTasks.map(
                              (afternoon) => ListTile(
                                title: Text(
                                  afternoon['task'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  afternoon["time"],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      color: const Color.fromARGB(255, 44, 44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Malam",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (eveningTasks.isEmpty)
                              Text(
                                "Tidak ada tugas",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ...eveningTasks.map(
                              (evening) => ListTile(
                                title: Text(
                                  evening['task'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  evening["time"],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "Saran:",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ...suggestions.map(
                      (saran) => ListTile(
                        leading: Icon(
                          Icons.lightbulb,
                          color: Colors.amber.shade400,
                        ),
                        title: Text(saran, style: GoogleFonts.poppins()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
