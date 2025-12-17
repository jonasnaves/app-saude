import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/drug_model.dart';

class BusinessDataSource {
  final ApiService apiService;

  BusinessDataSource(this.apiService);

  Future<double> getCredits() async {
    final response = await apiService.get(ApiConstants.credits);
    return (response.data['credits'] ?? 0).toDouble();
  }

  Future<List<DrugModel>> getDrugs({String? search}) async {
    final response = await apiService.get(
      ApiConstants.drugs,
      queryParameters: search != null ? {'search': search} : null,
    );
    return (response.data as List)
        .map((json) => DrugModel.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> checkout(List<String> drugIds) async {
    final response = await apiService.post(
      ApiConstants.checkout,
      data: {
        'drugIds': drugIds,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await apiService.get(ApiConstants.transactions);
    return response.data;
  }
}

