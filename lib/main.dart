import 'package:flutter/material.dart';
import 'dart:async';
import 'client_page.dart';
import 'host_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  Future<void> hostPageDirect() async {
    // Navigate to host stream page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HostPage()),
    );
  }

  Future<void> clientPageDirect() async {
    // Navigate to receive stream page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter p2p connection plugin'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: hostPageDirect,
              child: Container(
                color: Colors.green[700],
                child: const Center(
                  child: Text(
                    "Host",
                    style: TextStyle(color: Colors.white, fontSize: 44),

                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: clientPageDirect,
              child: Container(
                color: Colors.amber[700],
                child: const Center(
                  child: Text(
                    "Client",
                    style: TextStyle(color: Colors.white, fontSize: 44),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
