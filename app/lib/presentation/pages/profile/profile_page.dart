import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: const Center(
        child: Text(
          'Página de perfil será implementada aqui',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

