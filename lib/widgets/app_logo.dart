import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});
  

  @override
  
  Widget build(BuildContext context) {

    return Column(
      
      children: [
        
        Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
         fit: BoxFit.contain,
        ),

        const SizedBox(height: 8),

        const Text(
          'LeafyPath',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5E7D68),
          ),
        ),
      ],
    );
  }
}