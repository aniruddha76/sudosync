import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(title: const Text('Control Panel')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: null, 
                      backgroundColor: Colors.white,
                      child: Icon(Icons.lock, color: Color.fromARGB(255, 8, 6, 6),),
                    ),
                    SizedBox(height: 8),
                    Text('Lock', style: TextStyle(color: Colors.white)),
                  ],
                ),

                SizedBox(width: 20),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: null, 
                      backgroundColor: Colors.white,
                      child: Icon(Icons.power_settings_new, color: Color.fromARGB(255, 8, 6, 6),),
                    ),
                    SizedBox(height: 8),
                    Text('Shutdown', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: null, 
                      backgroundColor: Colors.white,
                      child: Icon(Icons.restart_alt, color: Color.fromARGB(255, 8, 6, 6),),
                    ),
                    SizedBox(height: 8),
                    Text('Restart', style: TextStyle(color: Colors.white)),
                  ],
                ),
                
                SizedBox(width: 20),
                
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     FloatingActionButton(
                //       onPressed: null, 
                //       backgroundColor: Colors.white,
                //       child: Icon(Icons.add_circle, color: Color.fromARGB(255, 8, 6, 6),),
                //     ),
                //     SizedBox(height: 8),
                //     Text('Suspend', style: TextStyle(color: Colors.white)),
                //   ],
                // ),
              ],
            ), 
          ],
        ),
      ),
    );
  }
}
