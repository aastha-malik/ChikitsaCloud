import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/api_client.dart';

class HospitalProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _hospitals = [];
  List<dynamic> get hospitals => _hospitals;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNearbyWithGPS() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      final response = await _apiClient.dio.get('/hospitals/nearby', queryParameters: {
        'lat': position.latitude,
        'lng': position.longitude,
      });
      
      _hospitals = response.data;
    } catch (e) {
      _errorMessage = e.toString();
      _hospitals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyWithText(String location) async {
    if (location.isEmpty) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.dio.get('/hospitals/nearby', queryParameters: {
        'location': location,
      });
      _hospitals = response.data;
    } catch (e) {
      _errorMessage = "Failed to find location. Please try again.";
      _hospitals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
