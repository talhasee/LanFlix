import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:logger/logger.dart';

class OTPScreen extends StatefulWidget {
  final String myCode;
  OTPScreen({Key? key, required this.myCode}) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  String invalidValue = "";
  bool isOTPVerified = false; // Add this variable
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (mounted) {
      logger.d("Here inside");
      Navigator.pop(context, false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "PIN",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 80.0),
            ),
            Text("Enter PIN".toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 40.0),
            const Text("PIN", textAlign: TextAlign.center),
            const SizedBox(height: 20.0),
            OtpTextField(
              mainAxisAlignment: MainAxisAlignment.center,
              numberOfFields: 4,
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              onSubmit: (code) {
                if (widget.myCode == code) {
                  setState(() {
                    isOTPVerified = true;
                  });
                  Navigator.pop(context, true); // Return true if OTP is verified
                } else {
                  setState(() {
                    invalidValue = "Invalid PIN";
                  });
                }
              },
            ),
            const SizedBox(height: 20.0),
            Text(
              invalidValue,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("VERIFY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
