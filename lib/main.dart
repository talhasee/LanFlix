import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'client/client_page.dart';
import 'host/host_page.dart';

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
        leading: Image.asset('lib/assets/images/logo.png'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Image.asset('lib/assets/images/logo_tag.png'),
            const SizedBox(
              height: 64,
            ),
            Expanded(
              child: GestureDetector(
                onTap: hostPageDirect,
                child: Container(
                  decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(26)), color: Color(0xffff5C00)),
                  margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
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
                  decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(26)), color: Color(0xfff4f4f4)),
                  margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
                  child: const Center(
                    child: Text(
                      "Client",
                      style: TextStyle(color: Colors.black, fontSize: 44),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 64,
            ),
          ],
        ),
      ),
    );
  }
}
