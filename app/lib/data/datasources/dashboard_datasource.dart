import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardDataSource {
  final ApiService apiService;

  DashboardDataSource(this.apiService);

  Future<Map<String, dynamic>> getStats() async {
    final response = await apiService.get(ApiConstants.dashboardStats);
    return response.data;
  }

  Future<List<dynamic>> getSchedule() async {
    final response = await apiService.get(ApiConstants.schedule);
    return response.data;
  }
}

