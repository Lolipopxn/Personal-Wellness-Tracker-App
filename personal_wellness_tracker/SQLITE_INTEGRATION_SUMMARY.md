# Personal Wellness Tracker - SQLite Integration Summary

## การเปลี่ยนแปลงที่ดำเนินการแล้ว

### 1. เพิ่ม SQLite Database Service
- **ไฟล์**: `lib/app/database_service.dart` (มีอยู่แล้ว)
- สร้าง DatabaseService สำหรับจัดการ SQLite
- รองรับตาราง: user_profiles, food_logs, daily_tasks, exercise_logs, water_logs, sleep_logs, mood_logs

### 2. สร้าง Sync Service
- **ไฟล์ใหม่**: `lib/services/sync_service.dart`
- ดึงข้อมูลจาก Firebase Firestore และบันทึกลง SQLite
- รองรับการ sync ข้อมูล 30 วันย้อนหลัง
- มี Force Sync สำหรับลบข้อมูลเก่าและดาวน์โหลดใหม่

### 3. สร้าง Offline Data Service
- **ไฟล์ใหม่**: `lib/services/offline_data_service.dart`
- เป็นตัวกลางสำหรับการเข้าถึงข้อมูลจาก SQLite
- แทนที่ FirestoreService ในการใช้งานปกติ
- รองรับ Dashboard data, Weekly stats

### 4. สร้างหน้า Data Management
- **ไฟล์ใหม่**: `lib/pages/data_management_page.dart`
- แสดงสถานะข้อมูลใน SQLite
- ปุ่มสำหรับ Sync, Force Sync, ล้างข้อมูล
- แสดงจำนวนข้อมูลในแต่ละตาราง

### 5. อัปเดตไฟล์หลัก
- **main_scaffold.dart**: ใช้ OfflineDataService แทน FirestoreService
- **dashboard.dart**: ใช้ getDashboardData() จาก OfflineDataService
- **food_save.dart**: ใช้ OfflineDataService สำหรับ CRUD operations
- **daily_page.dart**: ใช้ OfflineDataService สำหรับ daily tasks
- **profile.dart**: ใช้ OfflineDataService สำหรับ user profile
- **setting_page.dart**: เพิ่มลิงค์ไปยัง Data Management page

### 6. Dependencies
- เพิ่ม `sqflite: ^2.3.0` และ `path: ^1.8.3` ใน pubspec.yaml

## วิธีการทำงาน

### การ Initialize
1. เมื่อแอปเริ่มต้น OfflineDataService จะตรวจสอบว่ามีข้อมูล User Profile ใน SQLite หรือไม่
2. หากไม่มี จะทำการ sync ข้อมูลจาก Firestore โดยอัตโนมัติ

### การใช้งานปกติ
1. แอปจะดึงข้อมูลจาก SQLite เป็นหลัก (offline-first approach)
2. ข้อมูลจะแสดงผลรวดเร็วเพราะไม่ต้องรอการเชื่อมต่ออินเทอร์เน็ต

### การ Sync
1. ผู้ใช้สามารถ sync ข้อมูลด้วยตนเองผ่านหน้า Data Management
2. Sync ปกติจะเพิ่มข้อมูลใหม่โดยไม่ลบข้อมูลเก่า
3. Force Sync จะลบข้อมูลเก่าและดาวน์โหลดใหม่ทั้งหมด

## ข้อดี
- **เร็วกว่า**: ไม่ต้องรอการเชื่อมต่ออินเทอร์เน็ตทุกครั้ง
- **ใช้งานได้แม้ออฟไลน์**: ข้อมูลที่ sync แล้วสามารถใช้งานได้แม้ไม่มีเน็ต
- **ประหยัด Data**: ลดการเรียกใช้ Firebase API
- **มี Backup**: ข้อมูลยังคงอยู่ใน Firebase และ SQLite

## ตัวอย่างการใช้งาน

```dart
// ดึงข้อมูล User Profile
final offlineService = OfflineDataService();
final profile = await offlineService.getUserProfile();

// ดึงข้อมูลอาหารของวันที่กำหนด
final foodLogs = await offlineService.getFoodLogsForDate('2025-08-11');

// ดึงข้อมูล Dashboard
final dashboardData = await offlineService.getDashboardData();

// Sync ข้อมูลจาก Firebase
final success = await offlineService.syncWithFirestore();
```

## การติดตั้งและรัน
1. เรียกใช้ `flutter pub get` เพื่อติดตั้ง dependencies
2. รันแอปด้วย `flutter run`
3. ไปที่หน้า Settings > การจัดการข้อมูล เพื่อตรวจสอบสถานะและ sync ข้อมูล
