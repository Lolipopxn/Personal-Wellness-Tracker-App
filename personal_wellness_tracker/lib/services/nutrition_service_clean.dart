import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NutritionService {
  // Mock API Configuration
  static const String _mockApiBaseUrl = ApiConfig.mockApiBaseUrl;
  static const String _mockApiEndpoint = ApiConfig.mockApiEndpoint;

  // ฟังก์ชันสำหรับตรวจสอบสถานะ Mock API
  static Future<bool> testMockAPIConnection() async {
    try {
      print('🧪 Testing MockAPI connection...');
      final url = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ MockAPI connected successfully - ${data.length} items available');
        return true;
      } else {
        print('❌ MockAPI connection failed - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ MockAPI connection error: $e');
      return false;
    }
  }

  // ฟังก์ชันสำหรับค้นหาข้อมูลทั้งหมดใน Mock API (สำหรับ debug)
  static Future<List<Map<String, dynamic>>> getAllMockAPIData() async {
    try {
      final url = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching all MockAPI data: $e');
      return [];
    }
  }

  // ฟังก์ชันสำหรับส่งข้อมูลรายการเดียวไปยัง MockAPI
  static Future<bool> postToMockAPI(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
      
      return response.statusCode == 201; // MockAPI returns 201 for successful creation
    } catch (e) {
      print('❌ Error posting to MockAPI: $e');
      return false;
    }
  }

  // ฟังก์ชันสำหรับลบข้อมูลทั้งหมดใน MockAPI
  static Future<bool> clearMockAPI() async {
    try {
      print('🗑️ Clearing all data from MockAPI...');
      
      // ดึงข้อมูลทั้งหมดก่อน
      final url = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // ลบทีละรายการ
        for (var item in data) {
          final deleteUrl = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint/${item['id']}');
          await http.delete(deleteUrl);
          await Future.delayed(const Duration(milliseconds: 200));
        }
        
        print('✅ MockAPI cleared successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error clearing MockAPI: $e');
      return false;
    }
  }

  // ฟังก์ชันหลักสำหรับดึงข้อมูลโภชนาการ (ใช้ MockAPI เท่านั้น)
  static Future<NutritionData?> getNutritionData(String foodName) async {
    try {
      // ทำความสะอาดชื่ออาหาร
      String cleanFoodName = foodName.trim().toLowerCase();
      print('🔍 Searching for: "$cleanFoodName"');
      
      // ใช้ Mock API เท่านั้น
      print('🌐 Using Mock API...');
      return await _fetchFromMockAPI(cleanFoodName);
      
    } catch (e) {
      print('Error fetching nutrition data: $e');
      return null;
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลจาก MockAPI
  static Future<NutritionData?> _fetchFromMockAPI(String foodName) async {
    try {
      print('📡 [MockAPI] Calling Mock API for: "$foodName"');
      
      // สร้าง URL สำหรับ Mock API
      final url = Uri.parse('$_mockApiBaseUrl$_mockApiEndpoint');
      print('🌐 [MockAPI] URL: $url');
      
      // เรียก Mock API
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 [MockAPI] Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📋 [MockAPI] Data Length: ${data.length} items');
        
        // ค้นหาข้อมูลที่ตรงกับชื่ออาหาร
        for (var item in data) {
          String itemName = (item['name'] ?? '').toString().toLowerCase();
          print('🔍 [MockAPI] Checking: "$itemName" vs "$foodName"');
          
          if (itemName == foodName.toLowerCase() || 
              itemName.contains(foodName.toLowerCase()) ||
              foodName.toLowerCase().contains(itemName)) {
            
            print('✅ [MockAPI] Match found: ${item['name']} (${item['calories']} cal)');
            return NutritionData(
              calories: (item['calories'] ?? 0).toDouble(),
              protein: (item['protein'] ?? 0).toDouble(),
              carbs: (item['carbs'] ?? item['carb'] ?? 0).toDouble(), // รองรับทั้ง carbs และ carb
              fat: (item['fat'] ?? 0).toDouble(),
              fiber: (item['fiber'] ?? 0).toDouble(),
              sugar: (item['sugar'] ?? 0).toDouble(),
            );
          }
        }
        
        print('❌ [MockAPI] No match found for "$foodName"');
        return null;
      }
      
      print('❌ [MockAPI] Request failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ [MockAPI] Error: $e');
      return null;
    }
  }

  // สร้างข้อมูลโภชนาการเริ่มต้นถ้าไม่มีข้อมูล
  static NutritionData getDefaultNutrition(int calories) {
    // ใช้ค่าจาก config
    return NutritionData(
      calories: calories.toDouble(),
      protein: calories * ApiConfig.defaultProteinPercentage / ApiConfig.proteinCaloriesPerGram,
      carbs: calories * ApiConfig.defaultCarbsPercentage / ApiConfig.carbsCaloriesPerGram,
      fat: calories * ApiConfig.defaultFatPercentage / ApiConfig.fatCaloriesPerGram,
      fiber: calories * ApiConfig.defaultFiberPercentage,
      sugar: calories * ApiConfig.defaultSugarPercentage / ApiConfig.carbsCaloriesPerGram,
    );
  }
}

class NutritionData {
  final double calories;
  final double protein;  // กรัม
  final double carbs;    // กรัม
  final double fat;      // กรัม
  final double fiber;    // กรัม
  final double sugar;    // กรัม

  NutritionData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
    };
  }

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
    );
  }
}
