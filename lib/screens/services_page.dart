import 'package:flutter/material.dart';
import '../service/ssh_service.dart';

class ServicesPage extends StatefulWidget {
  final SSHService ssh;

  const ServicesPage({super.key, required this.ssh});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, String>> allServices = [];
  List<Map<String, String>> filteredServices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final result = await widget.ssh.runCommand(
        "systemctl list-units --user --type=service --all --no-pager --no-legend",
      );

      List<Map<String, String>> parsed = [];

      for (var line in result.split('\n')) {
        if (line.trim().isEmpty) continue;

        final parts = line.trim().split(RegExp(r'\s+'));

        if (parts.length < 4) continue;

        parsed.add({
          "name": parts[0],
          "status": parts[3], // running / exited
        });
      }

      setState(() {
        allServices = parsed;
        filteredServices = parsed;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> runCommand(String command) async {
    await widget.ssh.run(command);
    loadServices();
  }

  void filterServices(String query) {
    setState(() {
      filteredServices = allServices.where((service) {
        final name = service["name"]!.toLowerCase();
        final status = service["status"]!.toLowerCase();
        final search = query.toLowerCase();

        return name.contains(search) || status.contains(search);
      }).toList();
    });
  }

  Widget serviceCard(String name, String status) {
    final isRunning = status == "running";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRunning
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: isRunning ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isRunning ? "Running" : "Stopped",
            style: TextStyle(
              color: isRunning ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: Text("Services")),
        backgroundColor: Colors.black,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 182, 255, 0),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: filterServices,
                    decoration: InputDecoration(
                      hintText: "Search services...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 182, 255, 0)),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: filteredServices
                        .map((s) => serviceCard(s["name"]!, s["status"]!))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
