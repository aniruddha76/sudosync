import 'package:flutter/material.dart';
import 'screens/login_page.dart';
// import 'screens/home_page.dart';
// import '../service/ssh_service.dart';

void main() {
  runApp(sudosync());
}

class sudosync extends StatelessWidget {
  const sudosync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      // home: HomePage(ssh: SSHService()),
      home: const LoginPage(),
    );
  }
}