import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  final String? correctPin;
  final VoidCallback onSuccess;

  const PinLockScreen({
    super.key,
    this.correctPin,
    required this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<int> _enteredPin = [];

  void _onKeyPress(int number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
      });
    }
  }

  void _verifyPin() {
    final pinString = _enteredPin.join();
    if (widget.correctPin == null || pinString == widget.correctPin) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN. Please try again.')),
      );
      setState(() {
        _enteredPin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'Enter Security PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 24),
            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isFilled ? AppTheme.primary : AppTheme.divider,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const Spacer(),
            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (int row = 0; row < 3; row++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int col = 1; col <= 3; col++)
                          _buildKey(row * 3 + col),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 64, height: 64),
                      _buildKey(0),
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary),
                        onPressed: _onBackspace,
                        iconSize: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(int number) {
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        onPressed: () => _onKeyPress(number),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: AppTheme.divider, width: 1),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$number',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
