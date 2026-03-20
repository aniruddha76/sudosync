import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../service/ssh_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final ip = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();

  final ssh = SSHService();

  bool isLoading = false;

  // late AnimationController controller;

  // @override
  // void initState() {
  //   super.initState();

  //   controller = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 800),
  //   )..repeat(reverse: true);
  // }

  Future<void> connect() async {
    setState(() {
      isLoading = true;
    });

    try {
      await ssh.connect(ip.text, user.text, pass.text);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomePage(ssh: ssh)),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Connection Failed"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
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

  // @override
  // void dispose() {
  //   controller.dispose();
  //   super.dispose();
  // }

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
                  decoration: const InputDecoration(
                    labelText: 'Ip address',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: user,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
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
