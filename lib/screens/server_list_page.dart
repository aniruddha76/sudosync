import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/server.dart';
import '../service/server_storage.dart';
import '../service/ssh_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final storage = ServerStorage();
  List<Server> servers = [];
  bool loading = true;

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

    await ssh.connect(server.host, server.username, server.password);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HomePage(ssh: ssh)),
    );
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
              await storage.deleteServer(server.id);
              loadServers();
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
                            onTap: () => connect(servers[index]),
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
                    shape: CircleBorder(
                    ),
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
