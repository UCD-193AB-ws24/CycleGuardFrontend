import 'package:flutter/material.dart';
import 'package:cycle_guard_app/pages/rocket_exhaust.dart';

class AnimatedButtonScreen extends StatefulWidget {
  const AnimatedButtonScreen({Key? key}) : super(key: key);

  @override
  _AnimatedButtonScreenState createState() => _AnimatedButtonScreenState();
}

class _AnimatedButtonScreenState extends State<AnimatedButtonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _riseToLaunchStationAnimation;
  late Animation<double> _liftOffFromLaunchStationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print("Animation finished! Closing screen...");
        Navigator.pop(context); 
      }
    });

    _riseToLaunchStationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _liftOffFromLaunchStationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInCirc),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return RocketExhaustWidget(
                launchProgress: _liftOffFromLaunchStationAnimation.value > 0
                    ? ((screenHeight * 2) * _liftOffFromLaunchStationAnimation.value +
                        screenHeight / 4)
                    : screenHeight / 4 * _riseToLaunchStationAnimation.value,
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: _liftOffFromLaunchStationAnimation.value > 0
                    ? ((screenHeight* 2) * _liftOffFromLaunchStationAnimation.value +
                        screenHeight / 4)
                    : screenHeight / 4 * _riseToLaunchStationAnimation.value,
                child: Center(
                  child: Icon(
                    Icons.rocket,
                    color: Color.fromARGB(255, 56, 15, 12),
                    size: 100,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}