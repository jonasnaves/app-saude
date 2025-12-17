import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class ClinicalDetailPage extends StatelessWidget {
  final String consultationId;

  const ClinicalDetailPage({super.key, required this.consultationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Detalhes da Consulta'),
      ),
      body: const Center(
        child: Text(
          'Detalhes da consulta serão exibidos aqui',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

