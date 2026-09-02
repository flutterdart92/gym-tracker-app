import 'package:flutter/material.dart';

class WorkoutTrackerPage extends StatelessWidget {
  const WorkoutTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      body: const Center(child: Text('Workout Log & Entry Screen')),
    );
  }
}
