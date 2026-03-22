import 'dart:async';
import 'package:flutter/material.dart';
import '../service/ssh_service.dart';

class SystemMonitor extends StatefulWidget {
  final SSHService ssh;

  const SystemMonitor({super.key, required this.ssh});

  @override
  State<SystemMonitor> createState() => _SystemMonitorState();
}

class Process {
  String pid;
  String name;
  String cpu;

  Process(this.pid, this.name, this.cpu);
}

class Disk {
  String mount;
  String size;
  String used;
  String percent;

  Disk(this.mount, this.size, this.used, this.percent);
}

class _SystemMonitorState extends State<SystemMonitor> {
  double cpu = 0;
  double memoryUsed = 0;
  double memoryTotal = 1;

  String loadAvg = "";
  double temperature = 0;

  List<Disk> disks = [];
  List<Process> processes = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    fetchStats();

    timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchStats());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      /// CPU
      String cpuOut = await widget.ssh.run(
        "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - \$8}'",
      );

      /// MEMORY
      String memOut = await widget.ssh.run(
        "free -m | awk 'NR==2{print \$3\" \"\$2}'",
      );

      /// LOAD AVG
      String loadOut = await widget.ssh.run(
        "uptime | awk -F'load average:' '{print \$2}'",
      );

      /// TEMP
      String tempOut = await widget.ssh.run(
        "cat /sys/class/thermal/thermal_zone0/temp",
      );

      /// DISKS
      String diskOut = await widget.ssh.run(
        "df -h --output=target,size,used,pcent | grep -E '^/(\$|home|boot|mnt|media)'",
      );

      /// TOP PROCESSES
      String procOut = await widget.ssh.run(
        "ps -eo pid,comm,%cpu --sort=-%cpu | head -11",
      );

      /// PARSE CPU
      double cpuVal = double.tryParse(cpuOut.trim()) ?? 0;

      /// PARSE MEMORY
      var memParts = memOut.trim().split(" ");

      double memUsed = double.tryParse(memParts[0]) ?? 0;
      double memTotal = double.tryParse(memParts[1]) ?? 1;

      /// PARSE TEMP
      double temp = (double.tryParse(tempOut.trim()) ?? 0) / 1000;

      /// PARSE DISKS
      List<Disk> diskList = [];

      for (var line in diskOut.trim().split("\n")) {
        var parts = line.trim().split(RegExp(r"\s+"));

        if (parts.length >= 4) {
          diskList.add(Disk(parts[0], parts[1], parts[2], parts[3]));
        }
      }

      disks = diskList;

      /// PARSE PROCESSES
      List<Process> procList = [];

      var lines = procOut.split("\n");

      for (int i = 1; i < lines.length; i++) {
        var parts = lines[i].trim().split(RegExp(r"\s+"));

        if (parts.length >= 3) {
          procList.add(Process(parts[0], parts[1], parts[2]));
        }
      }

      setState(() {
        cpu = cpuVal;

        memoryUsed = memUsed;
        memoryTotal = memTotal;

        loadAvg = loadOut.trim();

        temperature = temp;

        disks = diskList;

        processes = procList;
      });
    } catch (e) {
      // print("Monitor error: $e");
    }
  }

  Future<void> killProcess(String pid) async {
    await widget.ssh.run("kill -9 $pid");
  }

  Widget glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        // border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),

      child: child,
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return glassCard(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB6FF00)),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget memoryCard() {
    double percent = memoryUsed / memoryTotal;

    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Memory Usage", style: TextStyle(color: Colors.white70)),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: Colors.grey.shade800,
            color: const Color(0xFFB6FF00),
            borderRadius: BorderRadius.circular(5),
          ),

          const SizedBox(height: 10),

          Text(
            "${memoryUsed.toStringAsFixed(0)}MB / ${memoryTotal.toStringAsFixed(0)}MB",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget diskSection() {
    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Storage",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          const SizedBox(height: 15),

          ...disks.map((d) {
            double percent =
                double.tryParse(d.percent.replaceAll("%", ""))! / 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        d.mount == "/" ? "ROOT" : d.mount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "${d.used} / ${d.size}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade800,
                    color: const Color(0xFFB6FF00),
                    borderRadius: BorderRadius.circular(5),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    d.percent,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget processSection() {
    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Processes", style: TextStyle(color: Colors.white)),

          const SizedBox(height: 10),

          ...processes.map((p) {
            return ListTile(
              contentPadding: EdgeInsets.zero,

              title: Text(p.name, style: const TextStyle(color: Colors.white)),

              subtitle: Text(
                "CPU ${p.cpu} %",
                style: const TextStyle(color: Colors.white70),
              ),

              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),

                onPressed: () {
                  killProcess(p.pid);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("System Monitor"),
        backgroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: statCard(
                    "CPU Usage",
                    "${cpu.toStringAsFixed(1)} %",
                    Icons.memory,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: statCard(
                    "Temperature",
                    "${temperature.toStringAsFixed(1)} °C",
                    Icons.thermostat,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            memoryCard(),

            const SizedBox(height: 15),

            statCard("Load Average", loadAvg, Icons.speed),

            const SizedBox(height: 15),

            diskSection(),

            const SizedBox(height: 15),

            processSection(),
          ],
        ),
      ),
    );
  }
}
