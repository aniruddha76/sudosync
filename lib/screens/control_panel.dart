import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../service/ssh_service.dart';

class ControlPanel extends StatefulWidget {
  final SSHService ssh;

  const ControlPanel({super.key, required this.ssh});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {

  double volume = 0;
  double brightness = 0;
  bool isMuted = false;
  int loginSession = 0;

  @override
  void initState() {
    super.initState();
    fetchInitialValues();
  }

  Future<void> run(String cmd) async {
    await widget.ssh.run(cmd);
  }

  Future<void> fetchInitialValues() async {

    /// GET VOLUME
    String volOutput =
        await widget.ssh.run("pactl get-sink-volume @DEFAULT_SINK@");

    /// GET MUTE STATUS
    String muteOutput =
        await widget.ssh.run("pactl get-sink-mute @DEFAULT_SINK@");

    /// GET BRIGHTNESS
    String brightnessOutput =
        await widget.ssh.run("brightnessctl -m");

    /// PARSE VOLUME
    double vol = double.parse(
        volOutput.split("/")[1].trim().replaceAll("%", ""));

    /// PARSE MUTE
    bool muted = muteOutput.contains("yes");

    /// PARSE BRIGHTNESS
    double bright = double.parse(
        brightnessOutput.split(",")[3].replaceAll("%", ""));

    /// GET LOGIN SESSION (SAFER)
    String loginctlRaw = await widget.ssh.run(
        "loginctl list-sessions --no-legend | awk '{print \$1}' | head -n1");

    int loginctlOutput = int.tryParse(loginctlRaw.trim()) ?? 0;

    print("Loginctl Output: $loginctlOutput");

    setState(() {
      volume = vol;
      brightness = bright;
      isMuted = muted;
      loginSession = loginctlOutput;
    });
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor:
              backgroundColor ?? const Color.fromARGB(255, 255, 255, 255),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget brightnessSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Brightness",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),

        Slider(
          value: brightness,
          min: 0,
          max: 100,
          year2023: false,
          activeColor: const Color(0xFFB6FF00),
          inactiveColor: Colors.grey.shade800,
          label: brightness.round().toString(),

          onChanged: (v) async {
            setState(() => brightness = v);
            await run("brightnessctl set ${v.round()}%");
          },
        ),
      ],
    );
  }

  Widget volumeCircular() {
    return Column(
      children: [

        const Text(
          "Volume",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),

        const SizedBox(height: 10),

        SleekCircularSlider(
          min: 0,
          max: 100,
          initialValue: volume,

          appearance: CircularSliderAppearance(
            size: 250,

            customWidths: CustomSliderWidths(
              progressBarWidth: 15,
              handlerSize: 5,
              trackWidth: 10,
            ),

            customColors: CustomSliderColors(
              progressBarColor: const Color(0xFFB6FF00),
              trackColor: Colors.grey.shade800,
              dotColor: Colors.black,
              hideShadow: true,
            ),

            infoProperties: InfoProperties(
              modifier: (double value) {
                return "${value.round()}%";
              },
              mainLabelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),

          onChange: (v) {
            setState(() => volume = v);
          },

          onChangeEnd: (v) async {
            await run(
                "pactl set-sink-volume @DEFAULT_SINK@ ${v.round()}%");
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Control Panel"),
        backgroundColor: Colors.black,
      ),

      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              /// VOLUME CONTROL
              volumeCircular(),

              const SizedBox(height: 20),

              /// ACTION BUTTONS
              Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,

                children: [

                  actionButton(
                    icon: Icons.lock,
                    label: "Lock",
                    onTap: () => run("loginctl lock-session $loginSession"),
                  ),

                  actionButton(
                    icon: Icons.power_settings_new,
                    label: "Shutdown",
                    onTap: () => run("shutdown now"),
                  ),

                  actionButton(
                    icon: Icons.restart_alt,
                    label: "Restart",
                    onTap: () => run("reboot"),
                  ),

                  actionButton(
                    icon: Icons.bedtime,
                    label: "Suspend",
                    onTap: () => run("systemctl suspend"),
                  ),

                  actionButton(
                    icon: Icons.volume_off,
                    label: "Mute",
                    backgroundColor:
                        isMuted ? const Color(0xFFB6FF00) : Colors.white,
                    onTap: () async {
                      await run(
                          "pactl set-sink-mute @DEFAULT_SINK@ toggle");
                      fetchInitialValues();
                    },
                  ),

                  actionButton(
                    icon: Icons.monitor,
                    label: "Display Off",
                    onTap: () => run("xset dpms force off"),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// BRIGHTNESS CONTROL
              brightnessSlider(),
            ],
          ),
        ),
      ),
    );
  }
}
