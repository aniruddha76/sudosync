import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/ssh_service.dart';

class NetworkPage extends StatefulWidget {
  final SSHService ssh;

  const NetworkPage({super.key, required this.ssh});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {

  String interface = "--";
  String localIP = "--";
  String publicIP = "--";
  String connections = "--";
  String latency = "--";
  String packetLoss = "--";
  String firewall = "--";
  String openPorts = "--";

  double downloadSpeed = 0;
  double uploadSpeed = 0;

  int prevRxBytes = 0;
  int prevTxBytes = 0;

  List<FlSpot> downloadSpots = [];
  List<FlSpot> uploadSpots = [];

  double time = 0;
  Timer? timer;

  Map<String, String> portDescriptions = {
    "22": "SSH Remote Access",
    "80": "HTTP Web Server",
    "443": "HTTPS Secure Web",
    "21": "FTP File Transfer",
    "25": "SMTP Mail Server",
    "53": "DNS Service",
    "3306": "MySQL Database",
    "5432": "PostgreSQL Database",
    "6379": "Redis Cache",
    "27017": "MongoDB",
  };

  @override
  void initState() {
    super.initState();
    loadNetworkInfo();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadNetworkInfo() async {

    try {

      final iface =
          await widget.ssh.runCommand("ip route | grep default | awk '{print \$5}'");

      final ip =
          await widget.ssh.runCommand("hostname -I | awk '{print \$1}'");

      final pub =
          await widget.ssh.runCommand("curl -s ifconfig.me");

      final conn =
          await widget.ssh.runCommand("ss -s | grep TCP | awk '{print \$2}'");

      final ping =
          await widget.ssh.runCommand(
              "ping -c 3 8.8.8.8 | grep packet | awk -F ',' '{print \$3}' | awk '{print \$1}'");

      final latencyCmd =
          await widget.ssh.runCommand(
              "ping -c 1 8.8.8.8 | grep time= | awk -F'time=' '{print \$2}' | awk '{print \$1}'");

      final fw =
          await widget.ssh.runCommand("ufw status | head -n 1");

      final ports =
          await widget.ssh.runCommand(
              "ss -tuln | awk '{print \$5}' | sed '1d' | cut -d: -f2 | sort -u");

      if (!mounted) return;

      setState(() {
        interface = iface.trim();
        localIP = ip.trim();
        publicIP = pub.trim();
        connections = conn.trim().replaceAll('\n', ' / ');
        latency = "${latencyCmd.trim()} ms";
        packetLoss = ping.trim();
        firewall = fw.contains("active") ? "Active" : "Disabled";
        openPorts = ports.trim();
      });

      startTrafficMonitoring();

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void startTrafficMonitoring() {

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {

      try {

        final data =
            await widget.ssh.runCommand("cat /proc/net/dev | grep $interface");

        if (data.trim().isEmpty) return;

        final parts = data.trim().split(RegExp(r"\s+"));

        int rxBytes = int.tryParse(parts[1]) ?? 0;
        int txBytes = int.tryParse(parts[9]) ?? 0;

        if (prevRxBytes != 0) {

          int rxDiff = rxBytes - prevRxBytes;
          int txDiff = txBytes - prevTxBytes;

          downloadSpeed = (rxDiff * 8) / 1000000;
          uploadSpeed = (txDiff * 8) / 1000000;
        }

        prevRxBytes = rxBytes;
        prevTxBytes = txBytes;

        time++;

        downloadSpots.add(FlSpot(time, downloadSpeed));
        uploadSpots.add(FlSpot(time, uploadSpeed));

        if (downloadSpots.length > 30) {
          downloadSpots.removeAt(0);
          uploadSpots.removeAt(0);
        }

        if (mounted) setState(() {});

      } catch (e) {
        debugPrint(e.toString());
      }

    });
  }

  Widget trafficChart() {

    double maxY = 10;

    for (var s in downloadSpots) {
      if (s.y > maxY) maxY = s.y + 2;
    }

    for (var s in uploadSpots) {
      if (s.y > maxY) maxY = s.y + 2;
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white10),
          ),
          lineBarsData: [

            LineChartBarData(
              spots: downloadSpots,
              isCurved: true,
              color: Colors.limeAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),

            LineChartBarData(
              spots: uploadSpots,
              isCurved: true,
              color: Colors.white,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCard(IconData icon, String title, String value) {

    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0f0f0f),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [

          Icon(icon, color: Colors.limeAccent),

          const SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 12),
              ),

              Text(
                value,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),

            ],
          )
        ],
      ),
    );
  }

  Widget portsCard() {

    final portsList =
        openPorts.split('\n').where((p) => p.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff0f0f0f),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Open Ports",
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 12),

          ...portsList.map((port) {

            String desc =
                portDescriptions[port.trim()] ?? "Custom Service";

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.hub, color: Colors.limeAccent),
              title: Text(
                "Port $port",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                desc,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.circle,
                  size: 10, color: Colors.limeAccent),
            );

          }).toList()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff050505),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Network Monitor",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// Graph
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff0f0f0f),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text("Network Traffic",
                      style: GoogleFonts.poppins(
                          color: Colors.white70)),

                  const SizedBox(height: 10),

                  trafficChart(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "Download ${downloadSpeed.toStringAsFixed(2)} Mbps",
                        style: const TextStyle(
                            color: Colors.limeAccent),
                      ),

                      Text(
                        "Upload ${uploadSpeed.toStringAsFixed(2)} Mbps",
                        style: const TextStyle(color: Colors.white),
                      ),

                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Expanded(
                    child: statCard(Icons.link, "Connections", connections)),

                const SizedBox(width: 12),

                Expanded(
                    child: statCard(Icons.speed, "Latency", latency)),

              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                    child: statCard(Icons.public, "Public IP", publicIP)),

                const SizedBox(width: 12),

                Expanded(
                    child: statCard(Icons.wifi, "Packet Loss", packetLoss)),

              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                    child: statCard(Icons.router, "Interface", interface)),

                const SizedBox(width: 12),

                Expanded(
                    child: statCard(Icons.security, "Firewall", firewall)),

              ],
            ),

            const SizedBox(height: 16),

            portsCard()

          ],
        ),
      ),
    );
  }
}