import 'package:flutter/material.dart';
import 'package:sudosync/screens/server_list_page.dart';
import 'screens/login_page.dart';
import 'service/server_storage.dart';

void main() {
  runApp(sudosync());
}

class sudosync extends StatefulWidget {
  const sudosync({super.key});

  @override
  State<sudosync> createState() => _sudosyncState();
}

class _sudosyncState extends State<sudosync> {
  final storage = ServerStorage();
  bool loading = true;
  bool hasServers = false;

  @override
  void initState() {
    super.initState();
    checkServers();
  }

  void checkServers() async {

    final servers = await storage.getServers();

    setState(() {
      hasServers = servers.isNotEmpty;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: hasServers ? ServerListPage() : LoginPage(),
    );
  }
}