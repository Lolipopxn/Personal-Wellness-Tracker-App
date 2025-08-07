import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NutritionService {
  // ใช้ค่าจาก config file
  static const String _appId = ApiConfig.edamamAppId;
  static const String _appKey = ApiConfig.edamamAppKey;
  static const String _baseUrl = ApiConfig.edamamBaseUrl;
  
  // Mock API Configuration
  static const String _mockApiBaseUrl = ApiConfig.mockApiBaseUrl;
  static const String _mockApiEndpoint = ApiConfig.mockApiEndpoint;
  
  // ใช้ Mock API เป็นหลัก (เต็มรูปแบบ)
  static const bool _useMockApi = true;

  // ฟังก์ชันสำหรับเปลี่ยนโหมดการทำงาน
  static bool get isUsingMockApi => _useMockApi;
  
  // ฟังก์ชันสำหรับตั้งค่าใช้ Mock API เป็นหลัก
  static bool _useMockApiPrimary = true;
  static void setUseMockApiPrimary(bool useMockApi) {
    _useMockApiPrimary = useMockApi;
    print('🔧 MockAPI Primary mode set to: $useMockApi');
  }

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

  // ฟังก์ชันสำหรับส่งข้อมูลจาก Mock Database ไปยัง MockAPI
  static Future<bool> uploadMockDataToAPI() async {
    try {
      print('🚀 Starting to upload mock data to API...');
      int successCount = 0;
      int totalCount = _mockDatabase.length;
      
      for (String foodName in _mockDatabase.keys) {
        NutritionData nutrition = _mockDatabase[foodName]!;
        
        // สร้างข้อมูลที่จะส่ง
        Map<String, dynamic> dataToSend = {
          'name': foodName,
          'calories': nutrition.calories,
          'protein': nutrition.protein,
          'carb': nutrition.carbs, // ใช้ carb ตาม Schema ของ MockAPI
          'fat': nutrition.fat,
          'sugar': nutrition.sugar,
          'fiber': nutrition.fiber,
        };
        
        print('📤 Uploading: $foodName');
        
        // ส่งข้อมูลไปยัง MockAPI
        bool uploaded = await _postToMockAPI(dataToSend);
        if (uploaded) {
          successCount++;
          print('✅ Uploaded: $foodName');
        } else {
          print('❌ Failed to upload: $foodName');
        }
        
        // รอสักพักเพื่อไม่ให้ API overwhelmed
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('🎉 Upload completed: $successCount/$totalCount items uploaded');
      return successCount == totalCount;
    } catch (e) {
      print('❌ Error uploading mock data: $e');
      return false;
    }
  }

  // ฟังก์ชันสำหรับส่งข้อมูลรายการเดียวไปยัง MockAPI
  static Future<bool> _postToMockAPI(Map<String, dynamic> data) async {
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

  // ฟังก์ชันสำหรับลบข้อมูลทั้งหมดใน MockAPI (เผื่อต้องการเริ่มใหม่)
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

  // Mock data สำหรับการทดสอบ - เพิ่มอาหารไทยยอดนิยม
  static final Map<String, NutritionData> _mockDatabase = {
    'ข้าวผัด': NutritionData(
      calories: 250,
      protein: 8.5,
      carbs: 45.2,
      fat: 6.8,
      fiber: 2.1,
      sugar: 3.5,
    ),
    'ผัดไทย': NutritionData(
      calories: 320,
      protein: 12.3,
      carbs: 52.1,
      fat: 8.9,
      fiber: 3.2,
      sugar: 8.7,
    ),
    'ต้มยำกุ้ง': NutritionData(
      calories: 180,
      protein: 15.6,
      carbs: 8.4,
      fat: 7.2,
      fiber: 1.8,
      sugar: 4.1,
    ),
    'ส้มตำ': NutritionData(
      calories: 120,
      protein: 4.2,
      carbs: 18.6,
      fat: 3.8,
      fiber: 5.2,
      sugar: 12.3,
    ),
    'แกงเขียวหวาน': NutritionData(
      calories: 280,
      protein: 18.5,
      carbs: 12.8,
      fat: 16.3,
      fiber: 2.4,
      sugar: 7.6,
    ),
    'ข้าวขาว': NutritionData(
      calories: 130,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
      fiber: 0.4,
      sugar: 0.1,
    ),
    'ไก่ผัดเม็ดมะม่วงหิมพานต์': NutritionData(
      calories: 350,
      protein: 25.0,
      carbs: 15.0,
      fat: 22.0,
      fiber: 3.0,
      sugar: 8.0,
    ),
    'แกงส้ม': NutritionData(
      calories: 160,
      protein: 12.0,
      carbs: 10.0,
      fat: 8.0,
      fiber: 3.5,
      sugar: 6.0,
    ),
    'ลาบ': NutritionData(
      calories: 200,
      protein: 20.0,
      carbs: 8.0,
      fat: 10.0,
      fiber: 2.0,
      sugar: 3.0,
    ),
    'มันม่วงเผา': NutritionData(
      calories: 180,
      protein: 2.0,
      carbs: 40.0,
      fat: 0.5,
      fiber: 4.0,
      sugar: 8.0,
    ),
    'กล้วยทอด': NutritionData(
      calories: 200,
      protein: 2.5,
      carbs: 30.0,
      fat: 8.0,
      fiber: 2.5,
      sugar: 20.0,
    ),
    'สลัดผัก': NutritionData(
      calories: 90,
      protein: 3.2,
      carbs: 8.5,
      fat: 4.8,
      fiber: 4.2,
      sugar: 5.1,
    ),
    'สลัดไก่': NutritionData(
      calories: 180,
      protein: 22.5,
      carbs: 6.2,
      fat: 7.3,
      fiber: 3.8,
      sugar: 4.2,
    ),
    'โจ๊กหมู': NutritionData(
      calories: 280,
      protein: 14.8,
      carbs: 38.5,
      fat: 6.2,
      fiber: 1.8,
      sugar: 2.1,
    ),
    'ผัดกระเพราหมูสับ': NutritionData(
      calories: 320,
      protein: 18.6,
      carbs: 25.4,
      fat: 15.8,
      fiber: 2.4,
      sugar: 4.6,
    ),
    'ผัดผักรวม': NutritionData(
      calories: 110,
      protein: 4.5,
      carbs: 12.8,
      fat: 5.2,
      fiber: 5.8,
      sugar: 7.2,
    ),
    'มะม่วงข้าวเหนียว': NutritionData(
      calories: 300,
      protein: 4.0,
      carbs: 65.0,
      fat: 3.0,
      fiber: 3.0,
      sugar: 35.0,
    ),
    // เพิ่มอาหารไทยยอดนิยมเพิ่มเติม
    'ข้าวมันไก่': NutritionData(
      calories: 380,
      protein: 22.0,
      carbs: 35.0,
      fat: 18.0,
      fiber: 1.5,
      sugar: 2.0,
    ),
    'ผัดซีอิ๊ว': NutritionData(
      calories: 290,
      protein: 15.0,
      carbs: 38.0,
      fat: 9.0,
      fiber: 2.8,
      sugar: 5.0,
    ),
    'ข้าวผัดกุ้ง': NutritionData(
      calories: 320,
      protein: 18.0,
      carbs: 42.0,
      fat: 10.0,
      fiber: 2.0,
      sugar: 3.0,
    ),
    'ผัดกะเพรา': NutritionData(
      calories: 270,
      protein: 20.0,
      carbs: 12.0,
      fat: 16.0,
      fiber: 3.0,
      sugar: 4.0,
    ),
    'ผัดกระเพรา': NutritionData(
      calories: 270,
      protein: 20.0,
      carbs: 12.0,
      fat: 16.0,
      fiber: 3.0,
      sugar: 4.0,
    ),
    'กระเพรา': NutritionData(
      calories: 270,
      protein: 20.0,
      carbs: 12.0,
      fat: 16.0,
      fiber: 3.0,
      sugar: 4.0,
    ),

    'ข้าวซอย': NutritionData(
      calories: 350,
      protein: 16.0,
      carbs: 45.0,
      fat: 12.0,
      fiber: 3.5,
      sugar: 6.0,
    ),
    'แกงมัสมั่น': NutritionData(
      calories: 320,
      protein: 22.0,
      carbs: 15.0,
      fat: 20.0,
      fiber: 4.0,
      sugar: 8.0,
    ),
    'ยำวุ้นเส้น': NutritionData(
      calories: 150,
      protein: 8.0,
      carbs: 22.0,
      fat: 4.0,
      fiber: 2.0,
      sugar: 8.0,
    ),
    'ข้าวคลุกกะปิ': NutritionData(
      calories: 260,
      protein: 6.0,
      carbs: 48.0,
      fat: 5.0,
      fiber: 2.5,
      sugar: 8.0,
    ),
  };

  static Future<NutritionData?> getNutritionData(String foodName) async {
    try {
      // ทำความสะอาดชื่ออาหาร
      String cleanFoodName = foodName.trim().toLowerCase();
      print('🔍 Searching for: "$cleanFoodName"');
      
      // ใช้ Mock API เป็นหลัก (เต็มรูปแบบ)
      if (_useMockApiPrimary && _useMockApi) {
        print('🌐 [Primary] Using Mock API...');
        NutritionData? mockApiResult = await _fetchFromMockAPI(cleanFoodName);
        if (mockApiResult != null) {
          return mockApiResult;
        }
        
        // ถ้าไม่เจอใน Mock API ให้ลองใช้ Mock Database เป็น fallback
        print('🔄 [Fallback] Trying Mock Database...');
        NutritionData? mockDbResult = await _fetchFromMockDatabase(cleanFoodName);
        if (mockDbResult != null) {
          return mockDbResult;
        }
        
        // ถ้าไม่เจอทั้งคู่ ให้ลองใช้ Real API (ถ้ามี API key)
        if (_appId != 'YOUR_ACTUAL_APP_ID_HERE' && _appKey != 'YOUR_ACTUAL_APP_KEY_HERE') {
          print('� [Last Resort] Trying Real API...');
          return await _fetchFromAPI(foodName);
        }
        
        print('❌ No data found in any source');
        return null;
      }
      
      // Legacy fallback mode (ถ้าปิดการใช้ Mock API)
      print('🗃️ [Legacy] Using Mock Database only...');
      return await _fetchFromMockDatabase(cleanFoodName);
      
    } catch (e) {
      print('Error fetching nutrition data: $e');
      return null;
    }
  }

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

  static Future<NutritionData?> _fetchFromMockDatabase(String foodName) async {
    try {
      String cleanFoodName = foodName.trim().toLowerCase();
      print('🗃️ Searching in Mock Database for: "$cleanFoodName"');
      
      // ลองหาแบบตรงกันก่อน
      for (String key in _mockDatabase.keys) {
        if (key.toLowerCase() == cleanFoodName) {
          print('✅ Exact match found in Mock DB: $key');
          return _mockDatabase[key];
        }
      }
      
      // ลองหาแบบมีคำที่ตรงกัน
      for (String key in _mockDatabase.keys) {
        String keyLower = key.toLowerCase();
        if (keyLower.contains(cleanFoodName) || cleanFoodName.contains(keyLower)) {
          print('✅ Partial match found in Mock DB: $key');
          return _mockDatabase[key];
        }
      }
      
      // ลองหาคำที่คล้ายกัน
      List<String> searchWords = cleanFoodName.split(' ');
      for (String key in _mockDatabase.keys) {
        String keyLower = key.toLowerCase();
        for (String word in searchWords) {
          if (word.length >= 2 && keyLower.contains(word)) {
            print('✅ Keyword match found in Mock DB: $key (matched word: "$word")');
            return _mockDatabase[key];
          }
        }
      }
      
      print('❌ No match found in Mock Database');
      return null;
    } catch (e) {
      print('❌ Mock Database Error: $e');
      return null;
    }
  }

  static Future<NutritionData?> _fetchFromAPI(String foodName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?app_id=$_appId&app_key=$_appKey&ingr=${Uri.encodeComponent(foodName)}'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['calories'] != null) {
          return NutritionData(
            calories: (data['calories'] ?? 0).toDouble(),
            protein: (data['totalNutrients']?['PROCNT']?['quantity'] ?? 0).toDouble(),
            carbs: (data['totalNutrients']?['CHOCDF']?['quantity'] ?? 0).toDouble(),
            fat: (data['totalNutrients']?['FAT']?['quantity'] ?? 0).toDouble(),
            fiber: (data['totalNutrients']?['FIBTG']?['quantity'] ?? 0).toDouble(),
            sugar: (data['totalNutrients']?['SUGAR']?['quantity'] ?? 0).toDouble(),
          );
        }
      }
      return null;
    } catch (e) {
      print('API Error: $e');
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
