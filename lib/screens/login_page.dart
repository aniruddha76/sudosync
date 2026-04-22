import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sudosync/screens/app_dialog.dart';
import '../service/ssh_service.dart';
import '../service/server_storage.dart';
import '../models/server.dart';
import 'home_page.dart';
import 'dart:math';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ip = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();

  final ssh = SSHService();
  final storage = ServerStorage();

  bool isLoading = false;

  Future<void> connect() async {
    setState(() {
      isLoading = true;
    });

    try {
      await ssh.connect(ip.text, user.text, pass.text);

      String generateId() {
        return DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(9999).toString();
      }

      // SAVE SERVER AFTER SUCCESSFUL LOGIN
      await storage.saveServer(
        Server(
          id: generateId(),
          name: ip.text, 
          host: ip.text,
          username: user.text,
          password: pass.text,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(ssh: ssh)),
      );
    } catch (e) {
      AppDialog.show(
        type: DialogType.error,
        context: context,
        title: "Connection Failed",
        message: e.toString(),
        actions: [
          AppDialog.action(
            "OK",
            () => Navigator.pop(context),
          ),
        ],
      );  
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget animatedDots() {
    return LoadingAnimationWidget.progressiveDots(
      color: Colors.white,
      size: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),

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

                const SizedBox(height: 6),

                const Text(
                  'Please log in to continue',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),

                const SizedBox(height: 26),

                TextField(
                  controller: ip,
                  style: const TextStyle(color: Colors.white),

                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: user,
                  style: const TextStyle(color: Colors.white),

                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: pass,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),

                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 49,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : connect,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6FF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: isLoading
                        ? animatedDots()
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
