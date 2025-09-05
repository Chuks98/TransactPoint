import 'package:flutter/material.dart';

typedef PinCallback = void Function(String number);
typedef VoidCallbackAsync = Future<void> Function();

/// Keypad button widget
Widget keypadButton(
  BuildContext context,
  String text, {
  bool isSpecial = false,
  IconData? icon,
  required PinCallback onNumberPressed,
  required VoidCallback onDeletePressed,
}) {
  return GestureDetector(
    onTap: () {
      if (text == 'delete') {
        onDeletePressed();
      } else if (!isSpecial) {
        onNumberPressed(text);
      }
    },
    child: Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child:
            icon != null
                ? Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                )
                : Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
      ),
    ),
  );
}

/// PIN indicators row
Widget pinIndicators(BuildContext context, String pin) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(6, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              index < pin.length
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
        ),
      );
    }),
  );
}

/// PIN input section
Widget pinSection(
  BuildContext context, {
  required String pin,
  required bool isLoading,
  required VoidCallbackAsync onAuthenticate,
  required PinCallback onNumberPressed,
  required VoidCallback onDeletePressed,
  required ValueNotifier<bool> showPinNotifier, // new parameter
}) {
  final theme = Theme.of(context);

  return Column(
    children: [
      ValueListenableBuilder<bool>(
        valueListenable: showPinNotifier,
        builder: (context, showPin, _) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pin.isEmpty
                        ? 'Enter 6-digit Password'
                        : showPin
                        ? pin
                        : '•' * pin.length,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color:
                          pin.isEmpty
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (pin.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      showPinNotifier.value = !showPin;
                    },
                    child: Icon(
                      showPin ? Icons.visibility : Icons.visibility_off,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 16),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      pinIndicators(context, pin),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () {},
        child: Text(
          'Forgot Password?',
          style: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      const SizedBox(height: 30),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: pin.length == 6 && !isLoading ? onAuthenticate : null,
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Login',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
      const SizedBox(height: 30),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 15,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index == 9) return Container();
              if (index == 10)
                return keypadButton(
                  context,
                  '0',
                  onNumberPressed: onNumberPressed,
                  onDeletePressed: onDeletePressed,
                );
              if (index == 11)
                return keypadButton(
                  context,
                  'delete',
                  isSpecial: true,
                  icon: Icons.backspace_outlined,
                  onNumberPressed: onNumberPressed,
                  onDeletePressed: onDeletePressed,
                );
              return keypadButton(
                context,
                (index + 1).toString(),
                onNumberPressed: onNumberPressed,
                onDeletePressed: onDeletePressed,
              );
            },
          ),
        ),
      ),
    ],
  );
}

/// Biometric section
Widget biometricSection(
  BuildContext context, {
  required bool isLoading,
  required VoidCallbackAsync onAuthenticate,
  required Animation<double> pulseAnimation,
  required Future<void> Function() showFingerprintBottomSheet,
}) {
  final theme = Theme.of(context);

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: pulseAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(
                Icons.fingerprint,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 30),
      Text(
        'Click to log in with Fingerprint',
        style: theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.secondary,
        ),
      ),
      const SizedBox(height: 40),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : showFingerprintBottomSheet,
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Verify Fingerprint',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    ],
  );
}
