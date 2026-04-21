import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/server.dart';
import '../service/server_storage.dart';
import '../service/ssh_service.dart';
import 'home_page.dart';
import 'login_page.dart';

import 'app_dialog.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final storage = ServerStorage();
  List<Server> servers = [];
  bool loading = true;
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    loadServers();
  }

  void loadServers() async {
    final data = await storage.getServers();

    setState(() {
      servers = data;
      loading = false;
    });
  }

  void connect(Server server) async {
    final ssh = SSHService();

    try {
      await ssh.connect(server.host, server.username, server.password);
      if (!mounted) return;

      Navigator.pop(context); // Close the "Connecting..." dialog

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomePage(ssh: ssh)),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      AppDialog.show(
        context: context,
        title: "Connection Failed",
        message: e.toString(),
      );
    }

    if (mounted) {
      setState(() => connecting = false);
    }
  }

  void deleteServer(Server server) async {
    await storage.deleteServer(server.name);

    loadServers();
  }

  Widget serverCard(Server server) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFB6FF00),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.storage, color: Colors.black),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.host,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "user: ${server.username}",
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              AppDialog.show(
                context: context,
                title: "Delete Server",
                message: "Are you sure you want to delete below server?\nIP: ${server.host}\nUser: ${server.username}",
                type: DialogType.warning,
                actions: [
                  AppDialog.action("Cancel", () => Navigator.pop(context)),
                  AppDialog.action("Delete", () {
                    storage.deleteServer(server.id);
                    Navigator.pop(context);
                    loadServers();
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              Text(
                "SudoSync",
                style: GoogleFonts.lobsterTwo(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),

              Text(
                textAlign: TextAlign.center,
                "SudoSync is currently in early development. Please use with caution.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: 16),

              Row(
                children: [
                  Text(
                    "My Servers",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),

              SizedBox(height: 16),

              Expanded(
                child: servers.isEmpty
                    ? const Center(
                        child: Text(
                          "No servers added",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: servers.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: connecting
                                ? null
                                : () {
                                    
                                    if(connecting) return;
                                    
                                    setState(() => connecting = true);

                                    AppDialog.show(
                                      barrierDismissible: false,
                                      context: context,
                                      title: "Connecting to ${servers[index].host} as ${servers[index].username}",
                                      message: "Please wait while we establish a connection...",
                                    );

                                    connect(servers[index]);
                                  },
                            child: serverCard(servers[index]),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );

                    loadServers();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB6FF00),
                    shape: CircleBorder(),
                  ),

                  child: Icon(Icons.add, color: Colors.black, size: 35),
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Add Server",
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),

              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
