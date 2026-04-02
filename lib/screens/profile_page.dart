import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/ssh_service.dart';

class ProfilePage extends StatefulWidget {
  final SSHService ssh;

  const ProfilePage({super.key, required this.ssh});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Map<String, String> info = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {

    final result = await widget.ssh.runCommand("hostnamectl");
    final publicIp = await widget.ssh.runCommand("curl -s ifconfig.me");

    Map<String, String> parsed = {};

    for (var line in result.split("\n")) {
      if (line.contains(":")) {
        var parts = line.split(":");
        parsed[parts[0].trim()] = parts[1].trim();
      }
    }

    parsed["Public IP"] = publicIp.trim();

    setState(() {
      info = parsed;
      loading = false;
    });
  }

  Widget sectionTitle(String title) {

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFFB6FF00),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget infoTile(String title, String value) {

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [

          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          )

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      appBar: AppBar(
      automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Center(
          child: Text("Profile"),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 182, 255, 0),))
          : Padding(
              padding: const EdgeInsets.all(16),

              child: ListView(
                children: [

                  /// PROFILE ICON
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFFB6FF00),
                    child: Icon(
                      Icons.dns,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// HOSTNAME
                  Center(
                    child: Text(
                      info["Static hostname"] ?? "Server",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Center(
                    child: Text(
                      info["Operating System"] ?? "",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  /// SYSTEM SECTION
                  sectionTitle("System"),

                  infoTile("Hostname", info["Static hostname"] ?? ""),
                  infoTile("Operating System", info["Operating System"] ?? ""),
                  infoTile("Kernel", info["Kernel"] ?? ""),
                  infoTile("Architecture", info["Architecture"] ?? ""),

                  /// HARDWARE
                  sectionTitle("Hardware"),

                  infoTile("Machine ID", info["Machine ID"] ?? ""),
                  infoTile("Boot ID", info["Boot ID"] ?? ""),
                  infoTile("Chassis", info["Chassis"] ?? ""),

                ],
              ),
            ),
    );
  }
}