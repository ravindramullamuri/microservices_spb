// services/bmi_api.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/bmi/weight_height_model.dart';
import '../../providers/token_provider.dart';
import '../../utils/secure_storage_utils.dart';


class ApiService {

  final Ref _ref;
  ApiService(this._ref);

  String? get _token  {
      _ref.read(tokenProvider);
    return _ref.watch(tokenProvider);
  }
  Future<String?> _secureToken() async{
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    return token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };



  // ────── CREATE ──────
  Future<bool> create(WeightHeightLog log) async {
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);

    debugPrint('🔄 Creating log: ${log.toJson()}'); // Debug
    final uri = Uri.parse(ApiEndpoints.createPatientWeightHeight);
    final resp = await http.post(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }, body: jsonEncode(log.toJson())).timeout(timeoutDuration);

    debugPrint('📡 CREATE Response: ${resp.statusCode} - ${resp.body}'); // Debug

    _throwIfError(resp);

    // ✅ Only return on 201 - throw on any other status
    if (resp.statusCode != 201) {
      throw Exception('Create failed: Expected 201, got ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body)['data'];
    if (data == null) throw Exception('No data in response');

    return resp.statusCode == 201;
  }

  // ────── UPDATE ──────
  Future<bool> update(WeightHeightLog log) async {
    debugPrint('🔄 Updating log ${log.id}: ${log.toJson()}'); // Debug
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    debugPrint('Json Encode ${jsonEncode(log.toJson()).toString()}');
    final uri = Uri.parse(ApiEndpoints.updatePatientWeightHeight(log));
    final resp = await http.put(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }, body: jsonEncode(log.toJson())).timeout(timeoutDuration);

    debugPrint('📡 UPDATE Response: ${resp.statusCode} - ${resp.body}'); // Debug

    _throwIfError(resp);

    // ✅ Only return on 200 - throw on any other status
    if (resp.statusCode != 200) {
      throw Exception('Update failed: Expected 200, got ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body)['data'];
    if (data == null) throw Exception('No data in response');

    return resp.statusCode == 200;
  }

  // ────── HERO ──────
  Future<BmiResponse> heroDashboard() async {
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    debugPrint("BmiResponse @@@ $_token");
    final uri = Uri.parse(ApiEndpoints.heroDashboardOfBMI);
    final resp = await http.get(uri, headers:  {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(timeoutDuration);
    debugPrint('📡 Hero Response: ${resp.statusCode}'); // Debug

    _throwIfError(resp);
    final body = jsonDecode(resp.body);
    if (body['success'] != true) throw Exception(body['message'] ?? 'Hero failed');
    BmiResponse bmiResponse = BmiResponse.fromJson(jsonDecode(resp.body));
    if(bmiResponse.data!.bmiValue! >= 25){
      if(bmiResponse.data?.last24Hours?.changeType == ChangeType.increased){
        Future.delayed(
          Duration(minutes: 1),(){
          /*showNotificationNow(
              "Health Alert: Weight Rising Slightly",
              "Your Weight is now  (${bmiResponse.data!.bmiStatus}). \nA small ${bmiResponse.data?.last24Hours?.value} increase since last check — maintain a balanced diet and regular activity to stay healthy!"
          );*/
          }
        );
      }
    }
    return bmiResponse;
  }

  // ────── CURRENT + PAST ──────
  Future<CurrentAndPastData> currentAndPast() async {
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);
    final uri = Uri.parse(ApiEndpoints.userCurrentAndPastDataOfBMI);
    final resp = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }).timeout(timeoutDuration);
    debugPrint('📡 Current+Past Response: ${resp.statusCode}'); // Debug

    _throwIfError(resp);
    final body = jsonDecode(resp.body);
    if (body['success'] != true) throw Exception(body['message'] ?? 'Current/Past failed');
    return CurrentAndPastData.fromJson(body);
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode >= 400) {
      try {
        final err = jsonDecode(r.body);
        throw Exception(err['message'] ?? 'HTTP ${r.statusCode}');
      } catch (e) {
        throw Exception('HTTP ${r.statusCode}: ${r.body}');
      }
    }
  }
}