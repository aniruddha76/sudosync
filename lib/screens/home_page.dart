import 'package:flutter/material.dart';
import 'package:sudosync/screens/file_explorer.dart';
import 'package:sudosync/screens/services_page.dart';
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
  int selectedIndex = 0;

  String username = "Loading...";
  String hostname = "Loading...";
  String uptime = "Loading...";
  String totalMemory = "--";
  String memoryUsed = "--";
  String batteryStatus = "--";
  String date = "--";

  double memoryPercent = 0;
  List<String> recentDownloads = [];

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

      String downloads = await widget.ssh.run(
        "ls -t ~/Downloads 2>/dev/null | head -5",
      );

      double used = double.tryParse(usedMem.trim()) ?? 0;
      double total = double.tryParse(totalMem.trim()) ?? 1;

      setState(() {
        username = user.trim();
        hostname = host.trim();
        uptime = up.trim();
        memoryUsed = usedMem.trim();
        totalMemory = totalMem.trim();
        batteryStatus = battery.trim();
        date = time.trim();

        memoryPercent = used / total;
        recentDownloads = downloads
            .trim()
            .split("\n")
            .where((e) => e.isNotEmpty)
            .toList();
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
      width: 200,
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
              Text(
                "Uptime: $uptime",
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Memory",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$memoryUsed / $totalMemory MB",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Battery",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$batteryStatus %",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: memoryPercent,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return SafeArea(
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
                      backgroundImage: AssetImage("assets/avatar.png"),
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
                            color: Colors.white,
                          ),
                        ),
                        Text(date, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      widget.ssh.disconnect();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            systemCard(),

            const SizedBox(height: 10),

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
              children: [
                deviceCard(
                  title: "System Monitor",
                  subtitle: "Performance",
                  icon: Icons.computer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SystemMonitor(ssh: widget.ssh),
                      ),
                    );
                  },
                ),

                deviceCard(
                  title: "File Explorer",
                  subtitle: "Browse files",
                  icon: Icons.folder,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileExplorer(ssh: widget.ssh),
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
                        builder: (_) => ControlPanel(ssh: widget.ssh),
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
                        builder: (_) => TerminalScreen(ssh: widget.ssh),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              "Recent Downloads",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: recentDownloads
                    .map((download) => downloadItem(download))
                    .toList(),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget getPage() {
    switch (selectedIndex) {
      case 0:
        return homePage();

      case 1:
        return ServicesPage(ssh: widget.ssh);

      case 2:
        return const Center(
          child: Text("Network", style: TextStyle(color: Colors.white)),
        );

      case 3:
        return const Center(
          child: Text("Profile", style: TextStyle(color: Colors.white)),
        );

      default:
        return homePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),

      body: getPage(),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            navItem(Icons.home_rounded, "Home", 0),
            navItem(Icons.settings_rounded, "Services", 1),
            navItem(Icons.wifi_tethering, "Network", 2),
            navItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    bool selected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected
                ? const Color.fromARGB(255, 255, 255, 255)
                : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
