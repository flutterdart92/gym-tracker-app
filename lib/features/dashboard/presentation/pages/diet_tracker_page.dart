import 'package:flutter/material.dart';

class DietTrackerPage extends StatelessWidget {
  const DietTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Log')),
      body: const Center(child: Text('Meal & Calorie Log Screen')),
    );
  }
}
