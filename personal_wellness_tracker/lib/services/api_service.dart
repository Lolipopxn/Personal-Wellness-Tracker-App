import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ใช้ localhost สำหรับ web browser
  // ใช้ 10.0.2.2 สำหรับ Android Emulator  
  // ใช้ IP address ของเครื่อง (เช่น 192.168.1.100) สำหรับ physical device
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // Web browser
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Physical device
  
  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }
  
  // Get headers with authorization
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    print("DEBUG: Token found: ${token != null ? 'Yes' : 'No'}"); // Debug line
    if (token != null) {
      print("DEBUG: Token preview: ${token.substring(0, 20)}..."); // Debug line
    }
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Register user
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('Registering user: $email, $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );
      
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['access_token']);
        return data;
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Create user profile
  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/'),
        headers: headers,
        body: jsonEncode({
          'uid': userId,
          'email': profileData['email'],
          'username': profileData['username'],
          'age': profileData['age'],
          'gender': profileData['gender'],
          'weight': profileData['weight'],
          'height': profileData['height'],
          'blood_pressure': profileData['blood_pressure'],
          'heart_rate': profileData['heart_rate'],
          'health_problems': profileData['health_problems'],
          'profile_completed': profileData['profile_completed'] ?? true,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Profile creation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Create user goals
  Future<Map<String, dynamic>> createUserGoals({
    required String userId,
    required Map<String, dynamic> goals,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }
      
      final headers = await getHeaders();
      print('DEBUG API: Headers: $headers');
      
      final requestBody = {
        'user_id': userId,
        'goal_weight': goals['goal_weight'],
        'goal_exercise_frequency_week': goals['goal_exercise_frequency_week'],
        'goal_exercise_minutes': goals['goal_exercise_minutes'],
        'goal_water_intake': goals['goal_water_intake'],
        'goal_calorie_intake': goals['goal_calories'],
        'goal_sleep_hours': goals['goal_sleep_hours'],
        'activity_level': goals['activity_level'],
        'goal_timeframe': goals['goal_timeframe'],
        'is_active': true,
      };
      
      print('DEBUG API: Sending to ${baseUrl}/users/$userId/goals/');
      print('DEBUG API: Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/goals/'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Goals creation failed: ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Error in createUserGoals: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Create user preferences (health info)
  Future<Map<String, dynamic>> createUserPreferences({
    required String userId,
    required Map<String, dynamic> healthInfo,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/preferences/'),
        headers: headers,
        body: jsonEncode({
          'health_conditions': healthInfo['healthProblems'],
          'blood_pressure': healthInfo['bloodPressure'],
          'heart_rate': healthInfo['heartRate'],
          'notification_enabled': true,
          'privacy_level': 'private',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Preferences creation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      print('DEBUG: Getting current user, token exists: ${token != null}');
      
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }
      
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );
      
      print('DEBUG: getCurrentUser response status: ${response.statusCode}');
      print('DEBUG: getCurrentUser response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid, clear it
        await logout();
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Failed to get user info: ${response.body}');
      }
    } catch (e) {
      print('DEBUG: getCurrentUser error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Save daily task
  Future<Map<String, dynamic>> saveDailyTask({
    required Map<String, dynamic> taskData,
    required DateTime dateTime,
  }) async {
    try {
      final headers = await getHeaders();
      final String date = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
      
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: headers,
        body: jsonEncode({
          'task_date': date,
          'mood_score': taskData['mood'],
          'sleep_hours': taskData['sleep'],
          'exercise_minutes': taskData['exercise'],
          'water_glasses': taskData['water'],
          'notes': taskData['notes'] ?? '',
          'is_completed': true,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Task save failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get daily task
  Future<Map<String, dynamic>?> getDailyTask(DateTime dateTime) async {
    try {
      final headers = await getHeaders();
      final String date = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$date'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get task: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add food log
  Future<Map<String, dynamic>> addFoodLog({
    required String date,
    required Map<String, dynamic> mealData,
  }) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/food-logs/'),
        headers: headers,
        body: jsonEncode({
          'log_date': date,
          'meal_type': mealData['mealType'],
          'food_name': mealData['foodName'],
          'quantity': mealData['quantity'] ?? 1,
          'calories': mealData['calories'],
          'protein': mealData['protein'] ?? 0,
          'carbs': mealData['carbs'] ?? 0,
          'fat': mealData['fat'] ?? 0,
          'notes': mealData['notes'] ?? '',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Food log failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get food logs for date
  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/food-logs/$date'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Update food log
  Future<Map<String, dynamic>> updateFoodLog({
    required String foodLogId,
    required Map<String, dynamic> mealData,
  }) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/food-logs/$foodLogId'),
        headers: headers,
        body: jsonEncode({
          'meal_type': mealData['mealType'],
          'food_name': mealData['foodName'],
          'quantity': mealData['quantity'] ?? 1,
          'calories': mealData['calories'],
          'protein': mealData['protein'] ?? 0,
          'carbs': mealData['carbs'] ?? 0,
          'fat': mealData['fat'] ?? 0,
          'notes': mealData['notes'] ?? '',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Food log update failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete food log
  Future<void> deleteFoodLog(String foodLogId) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/food-logs/$foodLogId'),
        headers: headers,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Food log deletion failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all logs (tasks and food)
  Future<Map<String, dynamic>> fetchAllLogs() async {
    try {
      final headers = await getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/logs/all'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch logs: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get saved days count
  Future<int> getSavedDaysCount() async {
    try {
      final headers = await getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/stats/saved-days'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Get streak count
  Future<int> getStreakCount() async {
    try {
      final headers = await getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/stats/streak'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['streak'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    final headers = await getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user profile: ${response.body}');
    }
  }

  // Update user goals
  Future<Map<String, dynamic>> updateUserGoals({
    required String userId,
    required Map<String, dynamic> goals,
  }) async {
    final headers = await getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/goals/'),
      headers: headers,
      body: jsonEncode({
        'goal_weight': goals['goal_weight'],
        'goal_exercise_frequency': goals['goal_exercise_frequency'],
        'goal_exercise_minutes': goals['goal_exercise_minutes'],
        'goal_water_intake': goals['goal_water_intake'],
        'is_active': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user goals: ${response.body}');
    }
  }

  // Update user preferences
  Future<Map<String, dynamic>> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> healthInfo,
  }) async {
    final headers = await getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/preferences/'),
      headers: headers,
      body: jsonEncode(healthInfo),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user preferences: ${response.body}');
    }
  }

  // Food Logs methods
  Future<Map<String, dynamic>?> getFoodLogByDate(String userId, DateTime date) async {
    final headers = await getHeaders();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/food-logs/$dateStr'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // No food log for this date
    } else {
      throw Exception('Failed to get food log: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createFoodLog({
    required String userId,
    required DateTime date,
  }) async {
    final headers = await getHeaders();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/food-logs/'),
      headers: headers,
      body: jsonEncode({
        'date': dateStr,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create food log: ${response.body}');
    }
  }

  // Meals methods
  Future<List<Map<String, dynamic>>> getMealsByFoodLog(String foodLogId) async {
    final headers = await getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/food-logs/$foodLogId/meals/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> mealsData = jsonDecode(response.body);
      return mealsData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get meals: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createMeal({
    required String foodLogId,
    required String userId,
    required String foodName,
    String? description,
    required String mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    bool? hasNutritionData,
    String? imageUrl,
  }) async {
    final headers = await getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/meals/'),
      headers: headers,
      body: jsonEncode({
        'food_log_id': foodLogId,
        'user_id': userId,
        'food_name': foodName,
        if (description != null && description.isNotEmpty) 'description': description,
        'meal_type': mealType,
        if (calories != null) 'calories': calories,
        if (protein != null) 'protein': protein,
        if (carbs != null) 'carbs': carbs,
        if (fat != null) 'fat': fat,
        if (fiber != null) 'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (hasNutritionData != null) 'has_nutrition_data': hasNutritionData,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create meal: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateMeal({
    required String mealId,
    required String foodName,
    String? description,
    required String mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    bool? hasNutritionData,
    String? imageUrl,
  }) async {
    final headers = await getHeaders();

    final response = await http.put(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: headers,
      body: jsonEncode({
        'food_name': foodName,
        if (description != null && description.isNotEmpty) 'description': description,
        'meal_type': mealType,
        if (calories != null) 'calories': calories,
        if (protein != null) 'protein': protein,
        if (carbs != null) 'carbs': carbs,
        if (fat != null) 'fat': fat,
        if (fiber != null) 'fiber': fiber,
        if (sugar != null) 'sugar': sugar,
        if (hasNutritionData != null) 'has_nutrition_data': hasNutritionData,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update meal: ${response.body}');
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final headers = await getHeaders();

    final response = await http.delete(
      Uri.parse('$baseUrl/meals/$mealId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete meal: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> uploadMealImage(String imagePath) async {
    try {
      final headers = await getHeaders();
      headers.remove('Content-Type'); // Remove for multipart

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/meals/upload-image/'),
      );

      request.headers.addAll(headers);
      
      // ตรวจสอบไฟล์ก่อนอัปโหลด
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }
      
      final fileSize = await file.length();
      print('Uploading file: $imagePath, size: $fileSize bytes');
      
      if (fileSize > 5 * 1024 * 1024) { // 5MB
        throw Exception('File size must be less than 5MB');
      }
      
      // ตรวจสอบและกำหนด content type ที่ถูกต้อง
      String? contentType;
      final extension = imagePath.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          throw Exception('Only JPEG, PNG, JPG, and WebP images are allowed');
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imagePath,
        contentType: MediaType.parse(contentType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Get user goals
  Future<Map<String, dynamic>?> getUserGoals(String userId) async {
    try {
      final headers = await getHeaders();
      final url = '$baseUrl/users/$userId/goals/';  // เพิ่ม slash ท้าย
      print("DEBUG: Getting user goals from URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print("DEBUG: Get user goals response status: ${response.statusCode}");
      print("DEBUG: Get user goals response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend ส่งกลับมาเป็น List แต่เราต้องการ single object
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first);  // เอา item แรกและ cast เป็น Map<String, dynamic>
        } else if (data is Map) {
          return Map<String, dynamic>.from(data);  // ถ้าเป็น Map ให้ cast และส่งกลับ
        } else {
          return null;  // ถ้าไม่มีข้อมูล
        }
      } else if (response.statusCode == 404) {
        // Goals not found, return null
        return null;
      } else {
        throw Exception('Failed to get user goals: ${response.body}');
      }
    } catch (e) {
      print("DEBUG: Error getting user goals: $e");
      return null; // Return null instead of throwing to handle gracefully
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final headers = await getHeaders();
      final url = '$baseUrl/users/$userId/preferences/';  // เพิ่ม slash ท้าย
      print("DEBUG: Getting user preferences from URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print("DEBUG: Get user preferences response status: ${response.statusCode}");
      print("DEBUG: Get user preferences response body: ${response.body}");
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Preferences not found, return null
        return null;
      } else {
        throw Exception('Failed to get user preferences: ${response.body}');
      }
    } catch (e) {
      print("DEBUG: Error getting user preferences: $e");
      return null; // Return null instead of throwing to handle gracefully
    }
  }

  // Update food log statistics (total calories and meal count)
  Future<Map<String, dynamic>> updateFoodLogStats({
    required String foodLogId,
    required int totalCalories,
    required int mealCount,
  }) async {
    try {
      final headers = await getHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/food-logs/$foodLogId/stats'),
        headers: headers,
        body: jsonEncode({
          'total_calories': totalCalories,
          'meal_count': mealCount,
        }),
      );
      
      print("DEBUG: Update food log stats response status: ${response.statusCode}");
      print("DEBUG: Update food log stats response body: ${response.body}");
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Food log stats update failed: ${response.body}');
      }
    } catch (e) {
      print("DEBUG: Error updating food log stats: $e");
      throw Exception('Network error: $e');
    }
  }
}
