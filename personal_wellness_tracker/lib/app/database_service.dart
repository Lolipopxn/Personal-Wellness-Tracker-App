import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'wellness_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // User Profile Table
    await db.execute('''
      CREATE TABLE user_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        username TEXT,
        age INTEGER,
        gender TEXT,
        weight REAL,
        height REAL,
        goal_weight REAL,
        goal_exercise_frequency INTEGER,
        goal_exercise_minutes INTEGER,
        goal_water_intake INTEGER,
        blood_pressure TEXT,
        heart_rate INTEGER,
        health_problems TEXT,
        profile_completed INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Food Logs Table
    await db.execute('''
      CREATE TABLE food_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        name TEXT NOT NULL,
        calories INTEGER,
        description TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Daily Tasks Table
    await db.execute('''
      CREATE TABLE daily_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        task_type TEXT NOT NULL,
        task_data TEXT,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Exercise Logs Table
    await db.execute('''
      CREATE TABLE exercise_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        exercise_type TEXT,
        duration_minutes INTEGER,
        calories_burned INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Water Intake Logs Table
    await db.execute('''
      CREATE TABLE water_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        total_cups INTEGER,
        target_cups INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Sleep Logs Table
    await db.execute('''
      CREATE TABLE sleep_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        sleep_start TEXT,
        sleep_end TEXT,
        sleep_duration_minutes INTEGER,
        sleep_quality INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Mood Logs Table
    await db.execute('''
      CREATE TABLE mood_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        mood_level INTEGER,
        mood_description TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_food_logs_uid_date ON food_logs(uid, date)');
    await db.execute('CREATE INDEX idx_daily_tasks_uid_date ON daily_tasks(uid, date)');
    await db.execute('CREATE INDEX idx_exercise_logs_uid_date ON exercise_logs(uid, date)');
    await db.execute('CREATE INDEX idx_water_logs_uid_date ON water_logs(uid, date)');
    await db.execute('CREATE INDEX idx_sleep_logs_uid_date ON sleep_logs(uid, date)');
    await db.execute('CREATE INDEX idx_mood_logs_uid_date ON mood_logs(uid, date)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here if needed in the future
  }

  // User Profile Methods
  Future<void> saveUserProfile(Map<String, dynamic> userProfileData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      'uid': userProfileData['uid'],
      'username': userProfileData['username'],
      'age': userProfileData['age'],
      'gender': userProfileData['gender'],
      'weight': userProfileData['weight'],
      'height': userProfileData['height'],
      'goal_weight': userProfileData['goals']?['weight'],
      'goal_exercise_frequency': userProfileData['goals']?['exerciseFrequency'],
      'goal_exercise_minutes': userProfileData['goals']?['exerciseMinutes'],
      'goal_water_intake': userProfileData['goals']?['waterIntake'],
      'blood_pressure': userProfileData['healthInfo']?['bloodPressure'],
      'heart_rate': userProfileData['healthInfo']?['heartRate'],
      'health_problems': userProfileData['healthInfo']?['healthProblems']?.join(','),
      'profile_completed': userProfileData['profileCompleted'] == true ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert(
      'user_profiles',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final db = await database;
    final results = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (results.isNotEmpty) {
      final data = results.first;
      return {
        'uid': data['uid'],
        'username': data['username'],
        'age': data['age'],
        'gender': data['gender'],
        'weight': data['weight'],
        'height': data['height'],
        'goals': {
          'weight': data['goal_weight'],
          'exerciseFrequency': data['goal_exercise_frequency'],
          'exerciseMinutes': data['goal_exercise_minutes'],
          'waterIntake': data['goal_water_intake'],
        },
        'healthInfo': {
          'bloodPressure': data['blood_pressure'],
          'heartRate': data['heart_rate'],
          'healthProblems': (data['health_problems'] as String?)?.split(',') ?? [],
        },
        'profileCompleted': data['profile_completed'] == 1,
        'createdAt': data['created_at'],
        'updatedAt': data['updated_at'],
      };
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = Map<String, dynamic>.from(updates);
    data['updated_at'] = now;

    await db.update(
      'user_profiles',
      data,
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // Food Log Methods
  Future<void> addFoodLog({
    required String uid,
    required String date,
    required Map<String, dynamic> mealData,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'uid': uid,
      'date': date,
      'meal_type': mealData['type'],
      'name': mealData['name'],
      'calories': mealData['cal'],
      'description': mealData['desc'],
      'created_at': now,
      'updated_at': now,
    };

    await db.insert('food_logs', data);
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String uid, String date) async {
    final db = await database;
    
    print('🗃️ Querying food_logs table with uid: $uid, date: $date');
    
    final results = await db.query(
      'food_logs',
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
      orderBy: 'created_at ASC',
    );

    print('🗃️ Raw query results: ${results.length} records found');
    if (results.isNotEmpty) {
      print('🗃️ Sample record: ${results.first}');
    }

    final mappedResults = results.map((row) => {
      'id': row['id'].toString(),
      'type': row['meal_type'],
      'name': row['name'],
      'cal': row['calories'],
      'desc': row['description'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    }).toList();

    print('🗃️ Mapped results: ${mappedResults.length} records');
    
    return mappedResults;
  }

  Future<void> updateFoodLog({
    required String uid,
    required String date,
    required String mealId,
    required Map<String, dynamic> mealData,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'meal_type': mealData['type'],
      'name': mealData['name'],
      'calories': mealData['cal'],
      'description': mealData['desc'],
      'updated_at': now,
    };

    await db.update(
      'food_logs',
      data,
      where: 'id = ? AND uid = ?',
      whereArgs: [int.parse(mealId), uid],
    );
  }

  Future<void> deleteFoodLog({
    required String uid,
    required String date,
    required String mealId,
  }) async {
    final db = await database;
    await db.delete(
      'food_logs',
      where: 'id = ? AND uid = ?',
      whereArgs: [int.parse(mealId), uid],
    );
  }

  // Clear all food logs for a specific date (used for sync)
  Future<void> clearFoodLogsForDate({
    required String uid,
    required String date,
  }) async {
    final db = await database;
    await db.delete(
      'food_logs',
      where: 'uid = ? AND date = ?',
      whereArgs: [uid, date],
    );
  }

  // Daily Tasks Methods
  Future<void> saveDailyTask(
    String uid,
    Map<String, dynamic> taskData,
    DateTime dateTime,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final date = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

    print('💾 DatabaseService.saveDailyTask: Saving for uid=$uid, date=$date');
    print('💾 DatabaseService.saveDailyTask: Input task data: $taskData');
    print('💾 DatabaseService.saveDailyTask: Task data keys: ${taskData.keys.toList()}');
    
    // Log each task in detail before saving
    taskData.forEach((key, value) {
      print('   - $key: $value (${value.runtimeType})');
      if (value is Map) {
        value.forEach((subKey, subValue) {
          print('     - $subKey: $subValue (${subValue.runtimeType})');
        });
      }
    });

    // Convert the entire taskData to JSON string for storage
    final jsonString = jsonEncode(taskData);
    print('💾 DatabaseService.saveDailyTask: JSON string to store: $jsonString');
    
    final data = {
      'uid': uid,
      'date': date,
      'task_type': 'daily_tasks',
      'task_data': jsonString, // Store as JSON
      'is_completed': 1, // Assume completed when saved
      'created_at': now,
      'updated_at': now,
    };

    print('💾 DatabaseService.saveDailyTask: Full record to insert: $data');

    try {
      await db.insert(
        'daily_tasks',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ DatabaseService.saveDailyTask: Successfully saved daily task');
      
      // Verify the save by reading it back
      final savedData = await getDailyTask(uid, dateTime);
      print('✅ DatabaseService.saveDailyTask: Verification read result: $savedData');
      
    } catch (e) {
      print('❌ DatabaseService.saveDailyTask: Error saving: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDailyTask(String uid, DateTime dateTime) async {
    final db = await database;
    final date = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

    print('🗄️ DatabaseService.getDailyTask: Querying with uid=$uid, date=$date');

    final results = await db.query(
      'daily_tasks',
      where: 'uid = ? AND date = ? AND task_type = ?',
      whereArgs: [uid, date, 'daily_tasks'],
    );

    print('🗄️ DatabaseService.getDailyTask: Found ${results.length} records');
    
    if (results.isEmpty) {
      print('🗄️ DatabaseService.getDailyTask: No records found');
      
      // Let's check if there are any records at all for this user
      final allUserRecords = await db.query(
        'daily_tasks',
        where: 'uid = ?',
        whereArgs: [uid],
      );
      print('🗄️ DatabaseService.getDailyTask: Total records for user: ${allUserRecords.length}');
      
      if (allUserRecords.isNotEmpty) {
        print('🗄️ DatabaseService.getDailyTask: Available dates for this user:');
        for (final record in allUserRecords) {
          print('   - Date: ${record['date']}, Task Type: ${record['task_type']}');
        }
      }
      
      return null;
    }

    try {
      // Parse JSON task_data
      final row = results.first;
      print('🗄️ DatabaseService.getDailyTask: Raw record found:');
      print('   - ID: ${row['id']}');
      print('   - UID: ${row['uid']}');
      print('   - Date: ${row['date']}');
      print('   - Task Type: ${row['task_type']}');
      print('   - Created At: ${row['created_at']}');
      print('   - Updated At: ${row['updated_at']}');
      
      final taskDataString = row['task_data'] as String;
      print('   - Raw JSON: $taskDataString');
      
      final parsedData = jsonDecode(taskDataString) as Map<String, dynamic>;
      print('   - Parsed data: $parsedData');
      
      return parsedData;
    } catch (e) {
      print('❌ DatabaseService.getDailyTask: Error parsing daily task data: $e');
      return null;
    }
  }

  // Exercise Log Methods
  Future<void> saveExerciseLog({
    required String uid,
    required String date,
    required String exerciseType,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'uid': uid,
      'date': date,
      'exercise_type': exerciseType,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert('exercise_logs', data);
  }

  // Water Log Methods
  Future<void> saveWaterLog({
    required String uid,
    required String date,
    required int totalCups,
    required int targetCups,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'uid': uid,
      'date': date,
      'total_cups': totalCups,
      'target_cups': targetCups,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert(
      'water_logs',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Sleep Log Methods
  Future<void> saveSleepLog({
    required String uid,
    required String date,
    required String sleepStart,
    required String sleepEnd,
    required int durationMinutes,
    required int quality,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'uid': uid,
      'date': date,
      'sleep_start': sleepStart,
      'sleep_end': sleepEnd,
      'sleep_duration_minutes': durationMinutes,
      'sleep_quality': quality,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert(
      'sleep_logs',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Mood Log Methods
  Future<void> saveMoodLog({
    required String uid,
    required String date,
    required int moodLevel,
    required String moodDescription,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'uid': uid,
      'date': date,
      'mood_level': moodLevel,
      'mood_description': moodDescription,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert(
      'mood_logs',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Utility Methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_profiles');
    await db.delete('food_logs');
    await db.delete('daily_tasks');
    await db.delete('exercise_logs');
    await db.delete('water_logs');
    await db.delete('sleep_logs');
    await db.delete('mood_logs');
  }

  Future<Map<String, int>> getDataCounts(String uid) async {
    final db = await database;
    
    final foodCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM food_logs WHERE uid = ?', [uid])
    ) ?? 0;
    
    final taskCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM daily_tasks WHERE uid = ?', [uid])
    ) ?? 0;
    
    final exerciseCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM exercise_logs WHERE uid = ?', [uid])
    ) ?? 0;

    return {
      'food_logs': foodCount,
      'daily_tasks': taskCount,
      'exercise_logs': exerciseCount,
    };
  }

  // Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
