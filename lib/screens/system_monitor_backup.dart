import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

class _SystemMonitorState extends State<SystemMonitor> {

  double cpu = 0;
  double temperature = 0;

  double diskUsed = 0;
  double diskTotal = 1;
  double diskPercent = 0;

  List<Process> processes = [];

  List<FlSpot> cpuHistory = [];
  int x = 0;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    fetchStats();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => fetchStats(),
    );
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
          "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - \$8}'");

      /// DISK
      String diskOut = await widget.ssh.run(
          "df -kh / | awk 'NR==2{print \$2\" \"\$3\" \"\$5}'");

      /// TEMP
      String tempOut = await widget.ssh.run(
          "cat /sys/class/thermal/thermal_zone0/temp");

      /// TOP PROCESSES
      String procOut = await widget.ssh.run(
          "ps -eo pid,comm,%cpu --sort=-%cpu | head -11");

      /// PARSE CPU
      double cpuVal = double.tryParse(cpuOut.trim()) ?? 0;

      /// PARSE DISK
      var diskParts = diskOut.trim().split(" ");

      double total = double.parse(
          diskParts[0].replaceAll("G", ""));

      double used = double.parse(
          diskParts[1].replaceAll("G", ""));

      double percent = double.parse(
          diskParts[2].replaceAll("%", ""));

      /// PARSE TEMP
      double temp = (double.tryParse(tempOut.trim()) ?? 0) / 1000;

      /// PARSE PROCESSES
      List<Process> procList = [];

      var lines = procOut.split("\n");

      for (int i = 1; i < lines.length; i++) {

        var parts =
            lines[i].trim().split(RegExp(r"\s+"));

        if (parts.length >= 3) {
          procList.add(
            Process(parts[0], parts[1], parts[2]),
          );
        }
      }

      setState(() {

        cpu = cpuVal;
        temperature = temp;

        diskTotal = total;
        diskUsed = used;
        diskPercent = percent;

        processes = procList;

        cpuHistory.add(
          FlSpot(x.toDouble(), cpuVal),
        );

        if (cpuHistory.length > 20) {
          cpuHistory.removeAt(0);
        }

        x++;
      });

    } catch (e) {
      print("Monitor error: $e");
    }
  }

  Future<void> killProcess(String pid) async {
    await widget.ssh.run("kill -9 $pid");
  }

  Widget glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }

  Widget cpuCard() {
    return glassCard(
      child: Column(
        children: [

          const Text(
            "CPU Usage",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 90,
            width: 90,
            child: CircularProgressIndicator(
              value: cpu / 100,
              strokeWidth: 8,
              color: const Color(0xFFB6FF00),
              backgroundColor: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${cpu.toStringAsFixed(1)} %",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget tempCard() {
    return glassCard(
      child: Column(
        children: [

          const Icon(
            Icons.thermostat,
            color: Color(0xFFB6FF00),
          ),

          const SizedBox(height: 10),

          Text(
            "${temperature.toStringAsFixed(1)} °C",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget diskCard() {
    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Disk Usage",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: diskUsed / diskTotal,
            minHeight: 10,
            backgroundColor: Colors.grey.shade800,
            color: const Color(0xFFB6FF00),
          ),

          const SizedBox(height: 10),

          Text(
            "${diskUsed.toStringAsFixed(0)} GB / ${diskTotal.toStringAsFixed(0)} GB",
            style: const TextStyle(color: Colors.white),
          ),

          Text(
            "$diskPercent %",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget cpuGraph() {
    return glassCard(
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(

            gridData: FlGridData(show: false),

            titlesData: FlTitlesData(show: false),

            borderData: FlBorderData(show: false),

            lineBarsData: [

              LineChartBarData(
                spots: cpuHistory,
                isCurved: true,
                color: const Color(0xFFB6FF00),
                barWidth: 3,
                dotData: FlDotData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget processList() {
    return glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Top Processes",
            style: TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 10),

          ...processes.map((p) {

            return ListTile(

              contentPadding: EdgeInsets.zero,

              title: Text(
                p.name,
                style: const TextStyle(
                    color: Colors.white),
              ),

              subtitle: Text(
                "CPU ${p.cpu} %",
                style: const TextStyle(
                    color: Colors.white70),
              ),

              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
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

                Expanded(child: cpuCard()),

                const SizedBox(width: 20),

                Expanded(child: tempCard()),
              ],
            ),

            const SizedBox(height: 20),

            diskCard(),

            const SizedBox(height: 20),

            cpuGraph(),

            const SizedBox(height: 20),

            processList(),
          ],
        ),
      ),
    );
  }
}