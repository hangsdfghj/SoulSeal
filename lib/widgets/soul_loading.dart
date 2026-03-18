import 'package:flutter/material.dart';

class SoulLoadingWidget extends StatefulWidget {
  final String message;
  const SoulLoadingWidget({super.key, required this.message});

  @override
  State<SoulLoadingWidget> createState() => _SoulLoadingWidgetState();
}

class _SoulLoadingWidgetState extends State<SoulLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA67C52).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA67C52).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 50,
                color: Color(0xFFA67C52),
              ),
            ),
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.message,
              key: ValueKey<String>(widget.message),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
