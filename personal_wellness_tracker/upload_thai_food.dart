import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🚀 Uploading Thai Food Data to MockAPI...');
  print('=' * 50);
  
  const String mockApiBaseUrl = 'https://6892c8eec49d24bce8684d97.mockapi.io/api/v1';
  const String mockApiEndpoint = '/nutrition';
  
  // ข้อมูลอาหารไทยตาม Schema ที่ถูกต้อง
  List<Map<String, dynamic>> thaiFoodData = [
    {
      'name': 'ข้าวผัด',
      'calories': 250,
      'protein': 8.5,
      'fat': 6.8,
      'carb': 45.2,
      'sugar': 3.5,
      'fiber': 2.1,
    },
    {
      'name': 'ผัดไทย',
      'calories': 320,
      'protein': 12.3,
      'fat': 8.9,
      'carb': 52.1,
      'sugar': 8.7,
      'fiber': 3.2,
    },
    {
      'name': 'ต้มยำกุ้ง',
      'calories': 180,
      'protein': 15.6,
      'fat': 7.2,
      'carb': 8.4,
      'sugar': 4.1,
      'fiber': 1.8,
    },
    {
      'name': 'ส้มตำ',
      'calories': 120,
      'protein': 4.2,
      'fat': 3.8,
      'carb': 18.6,
      'sugar': 12.3,
      'fiber': 5.2,
    },
    {
      'name': 'แกงเขียวหวาน',
      'calories': 280,
      'protein': 18.5,
      'fat': 16.3,
      'carb': 12.8,
      'sugar': 7.6,
      'fiber': 2.4,
    },
    {
      'name': 'ผัดกระเพรา',
      'calories': 270,
      'protein': 20.0,
      'fat': 16.0,
      'carb': 12.0,
      'sugar': 4.0,
      'fiber': 3.0,
    },
    {
      'name': 'ข้าวมันไก่',
      'calories': 380,
      'protein': 22.0,
      'fat': 18.0,
      'carb': 35.0,
      'sugar': 2.0,
      'fiber': 1.5,
    },
    {
      'name': 'มะม่วงข้าวเหนียว',
      'calories': 300,
      'protein': 4.0,
      'fat': 3.0,
      'carb': 65.0,
      'sugar': 35.0,
      'fiber': 3.0,
    },
  ];
  
  try {
    final url = Uri.parse('$mockApiBaseUrl$mockApiEndpoint');
    
    // 1. ส่งข้อมูลอาหารไทย
    print('📤 Uploading ${thaiFoodData.length} Thai food items...');
    List<Map<String, dynamic>> uploadedItems = [];
    
    for (int i = 0; i < thaiFoodData.length; i++) {
      var foodItem = thaiFoodData[i];
      print('📤 [${i + 1}/${thaiFoodData.length}] Uploading: ${foodItem['name']}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(foodItem),
      );
      
      if (response.statusCode == 201) {
        var createdItem = json.decode(response.body);
        uploadedItems.add(createdItem);
        print('   ✅ Success! ID: ${createdItem['id']}');
      } else {
        print('   ❌ Failed! Status: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
      
      // รอสักหน่อยเพื่อไม่ให้ API overwhelmed
      await Future.delayed(Duration(milliseconds: 400));
    }
    
    print('\n✅ Upload completed! Uploaded ${uploadedItems.length} items');
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n' + '=' * 50);
  print('🎯 Upload completed successfully!');
}
