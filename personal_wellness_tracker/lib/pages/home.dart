import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'), backgroundColor: Colors.lightGreen),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('นี่คือหน้า Home'),
            SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('ไปที่หน้า login'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Text('ไปที่หน้า profile'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('ไปที่หน้า register'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: Text('ไปที่หน้า Dashboad'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/food_save');
              },
              child: Text('ไปที่หน้า Food Save'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, '/daily');
              },
              child: Text('ไปที่หน้า Daily Page'),
            ),
          ],
        ),
      ),
    );
  }
}
