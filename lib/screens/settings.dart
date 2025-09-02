import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode; // Pass current theme state
  final VoidCallback toggleTheme; // Function to toggle

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode; // Local copy of theme state

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode; // Sync with parent state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Enable or disable dark theme"),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.toggleTheme(); // calls the root toggle
              },
              secondary: const Icon(Icons.brightness_6),
            ),
          ),
        ],
      ),
    );
  }
}
