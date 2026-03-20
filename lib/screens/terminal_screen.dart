import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'dart:typed_data';
import '../service/ssh_service.dart';

class TerminalScreen extends StatefulWidget {
  final SSHService ssh;

  const TerminalScreen({super.key, required this.ssh});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {

  final terminal = Terminal(maxLines: 10000);

  @override
  void initState() {
    super.initState();
    startTerminal();
  }

  Future<void> startTerminal() async {

    final client = widget.ssh.client;

    final session = await client?.shell(
      pty: SSHPtyConfig(
        width: 80,
        height: 24,
      ),
    );

    /// SSH -> Terminal
    session?.stdout.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });
    /// Terminal -> SSH
    terminal.onOutput = (data) {
      session?.stdin.add(Uint8List.fromList(data.codeUnits));
    };

    session?.stderr.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Terminal"),
        backgroundColor: Colors.black,
      ),

      body: TerminalView(
        terminal,
        backgroundOpacity: 1,
      ),
    );
  }
}