import 'package:flutter/material.dart';

class SocialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Social Page'),
          SizedBox(height: 8), // Spacing between lines
          Text('socially awkward cs students...'),
        ],
      ),
    );
  }
}