import 'package:flutter/material.dart';
import 'booking_screen.dart';
import '../operator/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)])),
            child: SafeArea(
                child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text('Operator Login', style: TextStyle(color: Colors.white)))
                  ])),
              Expanded(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.car_repair, size: 120, color: Colors.white),
                            const SizedBox(height: 32),
                            const Text('Tyre Change Service', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            const Text('Book your tyre change appointment quickly and easily', style: TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
                            const SizedBox(height: 48),
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 8),
                                child: const Text('Book Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))
                          ]))))
            ]))));
  }
}
