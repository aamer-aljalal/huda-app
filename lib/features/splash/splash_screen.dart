import 'package:flutter/material.dart';
import 'package:tarteel/Routes/AppRoutes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتظار لمدة 3 ثوانٍ ثم الانتقال للصفحة الرئيسية
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.homePage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
      
        child: Image.asset(
          'assets/img/icon/tarteel.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
          
        ),
      ),
    );
  }
}
