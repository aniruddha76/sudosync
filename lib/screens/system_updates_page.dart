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
  List<String> filteredUpdates = [];

  String error = "";
  String searchQuery = "";

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
      } else if (osRelease.contains("Ubuntu") ||
          osRelease.contains("Debian")) {
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

  void applySearch(String query) {
    setState(() {
      searchQuery = query;

      if (query.isEmpty) {
        filteredUpdates = updates;
      } else {
        filteredUpdates = updates
            .where(
              (item) => item.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  //last time i used band aid method for this one should work better
  Future<void> fetchArchUpdates() async {
    final result = await widget.ssh.runCommand("pacman -Qu");

    List<String> parsed = result
        .split("\n")
        .where((line) => line.trim().isNotEmpty)
        .toList();

    setState(() {
      updates = parsed;
      filteredUpdates = parsed;
      updateCount = parsed.length;
      isLoading = false;
    });
  }

  Future<void> fetchAptUpdates() async {
    final result = await widget.ssh.runCommand("apt list --upgradable");

    List<String> parsed = result
        .split("\n")
        .where(
          (line) =>
              line.trim().isNotEmpty &&
              line.contains("/") &&
              !line.startsWith("Listing..."),
        )
        .toList();

    setState(() {
      updates = parsed;
      filteredUpdates = parsed;
      updateCount = parsed.length;
      isLoading = false;
    });
  }

  Future<void> fetchDnfUpdates() async {
    final result = await widget.ssh.runCommand("dnf check-update");

    List<String> parsed = result
        .split("\n")
        .where(
          (line) => 
            line.trim().isNotEmpty && 
            line.contains(".") &&
            !line.startsWith("Last metadata")
          )
        .toList();

    setState(() {
      updates = parsed;
      filteredUpdates = parsed;
      updateCount = parsed.length;
      isLoading = false;
    });
  }

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2A2D),
            Color(0xFF1C1C1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Updates",
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "$updateCount Available",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.laptop_mac_rounded,
                color: Color.fromARGB(255, 172, 240, 1),
                size: 18,
              ),

              const SizedBox(width: 8),

              Text(
                osType,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            onChanged: applySearch,
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: "Search packages...",
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.25),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget updateItem(String pkg) {
    final updates = pkg.split(" ");

    var packageName = "Unknown";
    var currentVersion = "";
    var latestVersion = "";

    if(osType == "Debian/Ubuntu"){
      //example 
      //bash/jammy-updates 5.1-6ubuntu1.1 amd64 [upgradable from: 5.1-6ubuntu1]
      packageName = updates[0];
      currentVersion = updates.last.replaceAll("]", "");
      latestVersion = updates[1];
    } else if (osType == "Fedora"){
      //example 
      //bash.x86_64                     5.2.15-4.fc40                updates
      packageName = updates[0].split(".")[0];
      currentVersion = "";
      latestVersion = updates.firstWhere((element) => element.contains("fc"));
    } else if (osType == "Arch Linux"){
      //example
      //bash 5.2.15-1 -> 5.2.15-2
      packageName = updates.first;
      currentVersion = updates[1];
      latestVersion = updates.last;
    }

    // final packageName = updates.isNotEmpty ? updates[0] : "Unknown";
    // final currentVersion = updates.length > 1 ? updates[1] : "";
    // final latestVersion = updates.isNotEmpty ? updates.last : "";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packageName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  currentVersion,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Latest",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 172, 240, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                latestVersion,
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
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 172, 240, 1),
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            error,
            style: GoogleFonts.poppins(
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (filteredUpdates.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            updates.isEmpty
                ? "System is up to date!"
                : "No packages found",
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredUpdates.length,
        itemBuilder: (context, index) {
          return updateItem(filteredUpdates[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("System Updates"),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUpdates,
          ),
        ],
      ),
      body: Column(
        children: [
          summaryCard(),
          updatesList(),
        ],
      ),
    );
  }
}
