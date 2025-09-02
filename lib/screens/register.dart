import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // goes back to previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: "First Name"),
            ),
            SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(labelText: "Last Name"),
            ),
            SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "e.g. +1 234 567 8900",
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}
