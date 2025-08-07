// ไฟล์สำหรับเก็บ configuration constants
// ใน production ควรใช้ environment variables หรือ secure storage

class ApiConfig {
  // Edamam Nutrition Analysis API
  // สมัครฟรีได้ที่: https://developer.edamam.com/
  // แทนที่ด้วย API credentials ของคุณ
  static const String edamamAppId = 'YOUR_ACTUAL_APP_ID_HERE'; 
  static const String edamamAppKey = 'YOUR_ACTUAL_APP_KEY_HERE';
  
  // Mock API Configuration
  // ใช้ MockAPI สำหรับการทดสอบ
  static const String mockApiBaseUrl = 'https://6892c8eec49d24bce8684d97.mockapi.io/api/v1';
  static const String mockApiEndpoint = '/nutrition';
  
  // ตัวอย่างการใช้งาน API keys อื่นๆ
  // static const String spoonacularApiKey = 'YOUR_SPOONACULAR_KEY';
  // static const String nutritionixAppId = 'YOUR_NUTRITIONIX_APP_ID';
  // static const String nutritionixAppKey = 'YOUR_NUTRITIONIX_APP_KEY';
  
  // URL endpoints
  static const String edamamBaseUrl = 'https://api.edamam.com/api/nutrition-data';
  
  // API limits
  static const int maxApiCallsPerMonth = 100; // สำหรับ free tier
  
  // Default nutrition percentages สำหรับกรณีไม่มีข้อมูล
  static const double defaultProteinPercentage = 0.2;  // 20%
  static const double defaultCarbsPercentage = 0.5;    // 50%
  static const double defaultFatPercentage = 0.3;      // 30%
  static const double defaultFiberPercentage = 0.02;   // 2%
  static const double defaultSugarPercentage = 0.1;    // 10%
  
  // Calorie conversion factors
  static const double proteinCaloriesPerGram = 4.0;
  static const double carbsCaloriesPerGram = 4.0;
  static const double fatCaloriesPerGram = 9.0;
}

// สำหรับ production ให้ใช้วิธีนี้:
// 1. สร้างไฟล์ .env ในโฟลเดอร์ root
// 2. เพิ่ม flutter_dotenv ใน pubspec.yaml
// 3. อ่านค่าจาก environment variables
//
// ตัวอย่าง .env:
// EDAMAM_APP_ID=your_actual_app_id
// EDAMAM_APP_KEY=your_actual_app_key
