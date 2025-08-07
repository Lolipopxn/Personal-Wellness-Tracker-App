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
    {
      'name': 'แกงแปง',
      'calories': 220,
      'protein': 14.0,
      'fat': 12.0,
      'carb': 15.0,
      'sugar': 8.0,
      'fiber': 3.5,
    },
    {
      'name': 'ยำวุ้นเส้น',
      'calories': 150,
      'protein': 8.0,
      'fat': 4.0,
      'carb': 22.0,
      'sugar': 8.0,
      'fiber': 2.0,
    },
    {
      'name': 'ลาบหมู',
      'calories': 200,
      'protein': 18.0,
      'fat': 10.0,
      'carb': 8.0,
      'sugar': 3.0,
      'fiber': 2.0,
    },
    {
      'name': 'กบเปา',
      'calories': 320,
      'protein': 25.0,
      'fat': 18.0,
      'carb': 12.0,
      'sugar': 2.0,
      'fiber': 1.0,
    },
    {
      'name': 'ข้าวซอย',
      'calories': 350,
      'protein': 16.0,
      'fat': 12.0,
      'carb': 45.0,
      'sugar': 6.0,
      'fiber': 3.5,
    },
    {
      'name': 'หมูกะทะ',
      'calories': 380,
      'protein': 24.0,
      'fat': 22.0,
      'carb': 18.0,
      'sugar': 8.0,
      'fiber': 2.0,
    },
    {
      'name': 'แกงมัสมั่น',
      'calories': 320,
      'protein': 20.0,
      'fat': 18.0,
      'carb': 20.0,
      'sugar': 12.0,
      'fiber': 3.0,
    },
    {
      'name': 'ไก่ย่าง',
      'calories': 240,
      'protein': 28.0,
      'fat': 8.0,
      'carb': 10.0,
      'sugar': 6.0,
      'fiber': 1.0,
    },
    {
      'name': 'หมูปิ้ง',
      'calories': 280,
      'protein': 22.0,
      'fat': 15.0,
      'carb': 12.0,
      'sugar': 8.0,
      'fiber': 1.5,
    },
    {
      'name': 'ไส้กรอกอีสาน',
      'calories': 220,
      'protein': 12.0,
      'fat': 16.0,
      'carb': 8.0,
      'sugar': 2.0,
      'fiber': 1.0,
    },
    {
      'name': 'ข้าวคลุกกะปิ',
      'calories': 260,
      'protein': 6.0,
      'fat': 5.0,
      'carb': 48.0,
      'sugar': 8.0,
      'fiber': 2.5,
    },
    {
      'name': 'ผัดซีอิ๊ว',
      'calories': 290,
      'protein': 15.0,
      'fat': 9.0,
      'carb': 38.0,
      'sugar': 5.0,
      'fiber': 2.8,
    },
    {
      'name': 'ข้าวผัดกุ้ง',
      'calories': 320,
      'protein': 18.0,
      'fat': 10.0,
      'carb': 42.0,
      'sugar': 3.0,
      'fiber': 2.0,
    },
    {
      'name': 'โจ๊กหมู',
      'calories': 280,
      'protein': 14.8,
      'fat': 6.2,
      'carb': 38.5,
      'sugar': 2.1,
      'fiber': 1.8,
    },
    {
      'name': 'ข้าวต้มปลา',
      'calories': 200,
      'protein': 16.0,
      'fat': 4.0,
      'carb': 25.0,
      'sugar': 2.0,
      'fiber': 1.5,
    },
    {
      'name': 'แกงจืด',
      'calories': 120,
      'protein': 8.0,
      'fat': 3.0,
      'carb': 12.0,
      'sugar': 6.0,
      'fiber': 2.0,
    },
    {
      'name': 'น้ำพริกกะปิ',
      'calories': 80,
      'protein': 3.0,
      'fat': 2.0,
      'carb': 12.0,
      'sugar': 8.0,
      'fiber': 3.0,
    },
    {
      'name': 'ผัดผักรวม',
      'calories': 110,
      'protein': 4.5,
      'fat': 5.2,
      'carb': 12.8,
      'sugar': 7.2,
      'fiber': 5.8,
    },
    {
      'name': 'สลัดผัก',
      'calories': 90,
      'protein': 3.2,
      'fat': 4.8,
      'carb': 8.5,
      'sugar': 5.1,
      'fiber': 4.2,
    },
    {
      'name': 'สลัดไก่',
      'calories': 180,
      'protein': 22.5,
      'fat': 7.3,
      'carb': 6.2,
      'sugar': 4.2,
      'fiber': 3.8,
    },
    // ของว่างไทย
    {
      'name': 'กล้วยทอด',
      'calories': 200,
      'protein': 2.5,
      'fat': 8.0,
      'carb': 30.0,
      'sugar': 20.0,
      'fiber': 2.5,
    },
    {
      'name': 'ข้าวเหนียวหน้าสังขยา',
      'calories': 280,
      'protein': 5.0,
      'fat': 8.0,
      'carb': 50.0,
      'sugar': 25.0,
      'fiber': 2.0,
    },
    {
      'name': 'ทองยิบ',
      'calories': 150,
      'protein': 3.0,
      'fat': 8.0,
      'carb': 18.0,
      'sugar': 15.0,
      'fiber': 0.5,
    },
    {
      'name': 'ทองหยอด',
      'calories': 140,
      'protein': 2.5,
      'fat': 7.0,
      'carb': 20.0,
      'sugar': 18.0,
      'fiber': 0.5,
    },
    {
      'name': 'ฝอยทอง',
      'calories': 160,
      'protein': 4.0,
      'fat': 9.0,
      'carb': 18.0,
      'sugar': 16.0,
      'fiber': 0.5,
    },
    {
      'name': 'ขนมกล้วย',
      'calories': 180,
      'protein': 3.5,
      'fat': 6.0,
      'carb': 28.0,
      'sugar': 22.0,
      'fiber': 2.0,
    },
    {
      'name': 'ขนมเปียกปูน',
      'calories': 120,
      'protein': 2.0,
      'fat': 1.0,
      'carb': 28.0,
      'sugar': 20.0,
      'fiber': 1.0,
    },
    {
      'name': 'ข้าวหลามใส',
      'calories': 220,
      'protein': 4.0,
      'fat': 2.0,
      'carb': 48.0,
      'sugar': 12.0,
      'fiber': 3.0,
    },
    {
      'name': 'ข้าวต้มมัด',
      'calories': 180,
      'protein': 3.5,
      'fat': 1.5,
      'carb': 38.0,
      'sugar': 8.0,
      'fiber': 2.5,
    },
    {
      'name': 'มันม่วงเผา',
      'calories': 180,
      'protein': 2.0,
      'fat': 0.5,
      'carb': 40.0,
      'sugar': 8.0,
      'fiber': 4.0,
    },
    {
      'name': 'ข้าวโพดต้ม',
      'calories': 160,
      'protein': 5.0,
      'fat': 2.0,
      'carb': 35.0,
      'sugar': 12.0,
      'fiber': 4.0,
    },
    {
      'name': 'ไอศกรีมกะทิ',
      'calories': 180,
      'protein': 3.0,
      'fat': 12.0,
      'carb': 16.0,
      'sugar': 14.0,
      'fiber': 0.5,
    },
    {
      'name': 'ทับทิมกรอบ',
      'calories': 140,
      'protein': 2.0,
      'fat': 8.0,
      'carb': 16.0,
      'sugar': 12.0,
      'fiber': 1.0,
    },
    {
      'name': 'บัวลอย',
      'calories': 160,
      'protein': 3.0,
      'fat': 8.0,
      'carb': 20.0,
      'sugar': 15.0,
      'fiber': 1.0,
    },
    {
      'name': 'ลอดช่อง',
      'calories': 120,
      'protein': 1.5,
      'fat': 6.0,
      'carb': 16.0,
      'sugar': 12.0,
      'fiber': 0.5,
    },
    {
      'name': 'ขนมชั้น',
      'calories': 150,
      'protein': 2.0,
      'fat': 5.0,
      'carb': 25.0,
      'sugar': 18.0,
      'fiber': 1.0,
    },
    {
      'name': 'ขนมครก',
      'calories': 100,
      'protein': 2.5,
      'fat': 3.0,
      'carb': 16.0,
      'sugar': 8.0,
      'fiber': 1.5,
    },
    {
      'name': 'ขนมโตเกียว',
      'calories': 180,
      'protein': 4.0,
      'fat': 8.0,
      'carb': 24.0,
      'sugar': 12.0,
      'fiber': 1.0,
    },
    {
      'name': 'โรตี',
      'calories': 200,
      'protein': 6.0,
      'fat': 8.0,
      'carb': 28.0,
      'sugar': 15.0,
      'fiber': 2.0,
    },
    {
      'name': 'ข้าวเกรียบปากหม้อ',
      'calories': 120,
      'protein': 2.5,
      'fat': 5.0,
      'carb': 18.0,
      'sugar': 2.0,
      'fiber': 1.0,
    },
    {
      'name': 'เม็ดขนุน',
      'calories': 140,
      'protein': 3.0,
      'fat': 6.0,
      'carb': 20.0,
      'sugar': 15.0,
      'fiber': 1.0,
    },
    {
      'name': 'ขนมปังสังขยา',
      'calories': 250,
      'protein': 8.0,
      'fat': 12.0,
      'carb': 28.0,
      'sugar': 15.0,
      'fiber': 2.0,
    },
    {
      'name': 'น้ำแข็งใส',
      'calories': 80,
      'protein': 1.0,
      'fat': 0.5,
      'carb': 20.0,
      'sugar': 18.0,
      'fiber': 0.5,
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
