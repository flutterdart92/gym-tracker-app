import 'package:flutter/material.dart';

class prgoressscreen extends StatefulWidget {
  const prgoressscreen({
    super.key,
  });

  @override
  State<prgoressscreen> createState() => _prgoressscreenState();
}

class _prgoressscreenState extends State<prgoressscreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(),
          textAlign: TextAlign.center,
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // const Text(
            //   'Shake Animation',
            //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            // ),
            SizedBox(height: 20),
            // Container(
            //   width: 200,
            //   height: 200,
            //   color: Colors.blueAccent,
            //   child: const Center(
            //     child: Text(
            //       'Shake Me!',
            //       style: TextStyle(color: Colors.white, fontSize: 18),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
