import 'package:flutter/material.dart';
import '../service/ssh_service.dart';

class ServicesPage extends StatefulWidget {
  final SSHService ssh;

  const ServicesPage({super.key, required this.ssh});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, String>> services = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final result = await widget.ssh.runCommand(
        "systemctl list-units --type=service --no-pager --no-legend",
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
        services = parsed;
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

  Widget serviceCard(String name, String status) {
    final isRunning = status == "running";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isRunning ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Services"),
        backgroundColor: Colors.black,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(10),
              scrollDirection: Axis.vertical,
              children: services
                  .map((s) => serviceCard(s["name"]!, s["status"]!))
                  .toList(),
            ),
    );
  }
}
