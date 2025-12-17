import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineService {
  static const String _consultationsBox = 'consultations';
  static const String _pendingRequestsBox = 'pending_requests';
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_consultationsBox);
    await Hive.openBox(_pendingRequestsBox);

    // Monitorar conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _isOnline = results.any((result) => 
          result != ConnectivityResult.none
        );
      },
    );

    // Verificar estado inicial
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> saveConsultation(Map<String, dynamic> consultation) async {
    final box = Hive.box(_consultationsBox);
    await box.put(consultation['id'], consultation);
  }

  Future<List<Map<String, dynamic>>> getConsultations() async {
    final box = Hive.box(_consultationsBox);
    return box.values.map((value) => Map<String, dynamic>.from(value as Map)).toList();
  }

  Future<void> addPendingRequest(String id, Map<String, dynamic> request) async {
    final box = Hive.box(_pendingRequestsBox);
    await box.put(id, request);
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final box = Hive.box(_pendingRequestsBox);
    return box.values.map((value) => Map<String, dynamic>.from(value as Map)).toList();
  }

  Future<void> removePendingRequest(String id) async {
    final box = Hive.box(_pendingRequestsBox);
    await box.delete(id);
  }

  Future<void> clearPendingRequests() async {
    final box = Hive.box(_pendingRequestsBox);
    await box.clear();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

final offlineServiceProvider = Provider<OfflineService>((ref) {
  final service = OfflineService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

