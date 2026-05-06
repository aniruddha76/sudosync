import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/ssh_service.dart';

class SystemUpdatesPage extends StatefulWidget {
  final SSHService ssh;

  const SystemUpdatesPage({super.key, required this.ssh});

  @override
  State<SystemUpdatesPage> createState() => _SystemUpdatesPage();
}

class _SystemUpdatesPage extends State<SystemUpdatesPage> {
  bool isLoading = true;
  String osType = "Detecting...";
  int updateCount = 0;
  List<String> updates = [];
  String error = "";

  @override
  void initState() {
    super.initState();
    fetchUpdates();
  }

  Future<void> fetchUpdates() async {
    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      final osRelease = await widget.ssh.runCommand("cat /etc/os-release");

      if (osRelease.contains("Arch")) {
        osType = "Arch Linux";
        await fetchArchUpdates();
      } else if (osRelease.contains("Ubuntu") || osRelease.contains("Debian")) {
        osType = "Debian/Ubuntu";
        await fetchAptUpdates();
      } else if (osRelease.contains("Fedora")) {
        osType = "Fedora";
        await fetchDnfUpdates();
      } else {
        osType = "Unknown";
        throw "Unsupported OS";
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchAptUpdates() async {
    final result = await widget.ssh.runCommand("apt list --upgradable");

    List<String> parsed = result
        .split("\n")
        .where((l) => l.contains("/"))
        .toList();

    setState(() {
      updates = parsed;
      updateCount = parsed.length - 1;
      isLoading = false;
    });
  }

  Future<void> fetchArchUpdates() async {
    final result = await widget.ssh.runCommand("pacman -Qu");

    List<String> parsed = result.trim().isEmpty ? [] : result.split("\n");

    setState(() {
      updates = parsed;
      updateCount = parsed.length - 1;
      isLoading = false;
    });
  }

  Future<void> fetchDnfUpdates() async {
    final result = await widget.ssh.runCommand("dnf check-update");

    List<String> parsed = result
        .split("\n")
        .where((l) => l.contains("."))
        .toList();

    setState(() {
      updates = parsed;
      updateCount = parsed.length - 1;
      isLoading = false;
    });
  }

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Updates",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),

          const SizedBox(height: 6),

          Text(
            "$updateCount Available",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          Text(
            osType,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget updateItem(String pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.split(" ").first,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Text(pkg.split(" ").elementAt(1)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Available Version",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: const Color.fromARGB(255, 172, 240, 1),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pkg.split(" ").last,
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 172, 240, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget updatesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Text(error, style: TextStyle(color: Colors.red)),
      );
    }

    if (updates.isEmpty) {
      return Center(child: Text("System is up to date!"));
    }

    return ListView.builder(
      itemCount: updates.length - 1,
      itemBuilder: (context, index) {
        return updateItem(updates[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "System Updates",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchUpdates),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            summaryCard(),

            const SizedBox(height: 20),

            Expanded(child: updatesList()),
          ],
        ),
      ),
    );
  }
}
