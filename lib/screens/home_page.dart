import 'package:flutter/material.dart';
import 'package:sudosync/screens/file_explorer.dart';
import 'package:sudosync/screens/system_monitor.dart';
import '../service/ssh_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terminal_screen.dart';
import 'control_panel.dart';

class HomePage extends StatefulWidget {
  final SSHService ssh;

  const HomePage({super.key, required this.ssh});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = "Loading...";
  String hostname = "Loading...";
  String uptime = "Loading...";
  String totalMemory = "--";
  String memoryUsed = "--";
  String batteryStatus = "--";
  // String cpuUsage = "--";
  String date = "--";

  double memoryPercent = 0;

  @override
  void initState() {
    super.initState();
    loadSystemData();
  }

  Future<void> loadSystemData() async {
    try {
      String user = await widget.ssh.run("whoami");
      String host = await widget.ssh.run("uname -n");
      String up = await widget.ssh.run("uptime -p | sed 's/up //'");

      String usedMem = await widget.ssh.run(
        "free -m | awk '/Mem:/ {print \$3}'",
      );

      String totalMem = await widget.ssh.run(
        "free -m | awk '/Mem:/ {print \$2}'",
      );

      String battery = await widget.ssh.run(
        "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 'N/A'",
      );

      String time = await widget.ssh.run("date");

      double used = double.tryParse(usedMem.trim()) ?? 0;
      double total = double.tryParse(totalMem.trim()) ?? 1;

      setState(() {
        username = user.trim();
        hostname = host.trim();
        uptime = up.trim();
        memoryUsed = usedMem.trim();
        totalMemory = totalMem.trim();
        // cpuUsage = cpu.trim();
        batteryStatus = battery.trim();
        date = time.trim();

        memoryPercent = used / total;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget deviceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black, size: 40),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget downloadItem(String name) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.download, color: Colors.white),
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

  Widget systemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB6FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hostname,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 3),
              Text("Uptime: $uptime",
                  style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 10),

              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  /// MEMORY
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Memory",
                          style: TextStyle(color: Colors.black,
                          fontWeight: FontWeight.bold)),
                      Text(
                        "$memoryUsed / $totalMemory MB",
                        style: const TextStyle(
                            color: Colors.black),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),  

                  /// BATTERY
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Battery",
                          style: TextStyle(color: Colors.black,
                          fontWeight: FontWeight.bold)),
                      Text(
                        "$batteryStatus %",
                        style: const TextStyle(
                            color: Colors.black,)
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),

          //Memory Bar
          SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: memoryPercent,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.black),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadSystemData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),

            children: [

              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage:
                            AssetImage("assets/avatar.png"),
                      ),

                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi $username!",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            date,
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const CircleAvatar(
                    backgroundColor: Colors.black,
                    child:
                        Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SYSTEM CARD
              systemCard(),

              const SizedBox(height: 10),

              /// TITLE
              Center(
                child: Text(
                  "SudoSync",
                  style: GoogleFonts.lobsterTwo(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// GRID
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1,

                children: [

                  deviceCard(
                    title: "File Explorer",
                    subtitle: "Browse files",
                    icon: Icons.folder,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FileExplorer(ssh: widget.ssh),
                        ),
                      );
                    },
                  ),

                  deviceCard(
                    title: "System Monitor",
                    subtitle: "Performance",
                    icon: Icons.computer,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SystemMonitor(),
                        ),
                      );
                    },
                  ),

                  deviceCard(
                    title: "Control Panel",
                    subtitle: "Settings",
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ControlPanel(ssh: widget.ssh),
                        ),
                      );
                    },
                  ),

                  deviceCard(
                    title: "Terminal",
                    subtitle: "SSH Access",
                    icon: Icons.terminal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TerminalScreen(ssh: widget.ssh),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// RECENT DOWNLOADS
              const Text(
                "Recent Downloads",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    downloadItem("server.log"),
                    downloadItem("backup.tar.gz"),
                    downloadItem("config.json"),
                    downloadItem("system.log"),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}