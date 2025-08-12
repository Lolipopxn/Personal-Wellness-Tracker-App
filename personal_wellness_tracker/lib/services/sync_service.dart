import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app/database_service.dart';
import '../app/firestore_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> syncUserDataFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print('❌ Sync skipped: No internet connection.');
      return false;
    }

    try {
      print('🔄 Starting Two-Way Sync for user: ${user.uid}');

      await uploadLocalChangesToFirestore();
      await _syncUserProfile(user.uid);
      await _syncFoodLogs(user.uid);
      await _syncDailyTasks(user.uid);

      print('✅ Sync completed successfully');
      return true;
    } catch (e) {
      print('❌ Sync failed: $e');
      return false;
    }
  }

  Future<bool> uploadLocalChangesToFirestore() async {
    print('📤 Uploading local changes to Firestore...');
    try {
      final unsyncedProfiles = await _databaseService.getUnsyncedUserProfiles();
      if (unsyncedProfiles.isEmpty) {
        print('✅ No local changes to upload.');
        return true;
      }

      print('Found ${unsyncedProfiles.length} unsynced profile(s).');

      for (final profile in unsyncedProfiles) {
        final uid = profile['uid'] as String;
        final newUsername = profile['username'] as String?;

        final Map<String, dynamic> updateData = {'username': newUsername};

        await _firestoreService.updateUserData(updateData);

        if (newUsername != null &&
            _auth.currentUser?.displayName != newUsername) {
          await _auth.currentUser?.updateDisplayName(newUsername);
        }

        await _databaseService.markUserProfileAsSynced(uid);
        print('✅ Successfully uploaded changes for user $uid');
      }
      return true;
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }

  // Sync User Profile
  Future<void> _syncUserProfile(String uid) async {
    try {
      print('📱 Syncing user profile...');

      final userData = await _firestoreService.getUserData();
      if (userData != null && userData.isNotEmpty) {
        userData['uid'] = uid;

        if (userData['uid'] != null) {
          await _databaseService.saveUserProfile(userData);
          print(
            '✅ User profile synced: ${userData['username'] ?? 'No username'}',
          );
        } else {
          print('⚠️ User profile data invalid: missing uid');
        }
      } else {
        print('⚠️ No user profile found in Firestore for uid: $uid');
      }
    } catch (e) {
      print('❌ Error syncing user profile: $e');
    }
  }

  Future<void> _syncFoodLogs(String uid) async {
    try {
      print('🍽️ Syncing food logs...');

      final now = DateTime.now();
      int syncedDays = 0;

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final dateString =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        try {
          print('🍽️ Checking food logs for date: $dateString');

          final firebaseDateString = "${date.year}-${date.month}-${date.day}";
          print('🍽️ Trying Firebase format first: $firebaseDateString');
          var foodLogs = await _firestoreService.getFoodLogsForDate(
            firebaseDateString,
          );
          print(
            '🍽️ Retrieved ${foodLogs.length} food logs for $firebaseDateString from Firestore',
          );

          if (foodLogs.isEmpty) {
            print('🍽️ Trying zero-padded format: $dateString');
            foodLogs = await _firestoreService.getFoodLogsForDate(dateString);
            print(
              '🍽️ Retrieved ${foodLogs.length} food logs for $dateString from Firestore',
            );
          }

          if (foodLogs.isNotEmpty) {
            print(
              '🍽️ Processing ${foodLogs.length} food logs for $dateString...',
            );

            await _databaseService.clearFoodLogsForDate(
              uid: uid,
              date: dateString,
            );

            for (final meal in foodLogs) {
              print('🍽️ Processing meal: ${meal['name']} with data: $meal');
              final processedMeal = _processFirestoreData(meal);
              print('🍽️ Processed meal data: $processedMeal');

              await _databaseService.addFoodLog(
                uid: uid,
                date: dateString,
                mealData: processedMeal,
              );
            }
            syncedDays++;
            print(
              '✅ Successfully synced ${foodLogs.length} food logs for $dateString',
            );
          } else {
            print('📭 No food logs found for $dateString in either format');
          }
        } catch (e) {
          print('⚠️ Error syncing food logs for $dateString: $e');
        }
      }

      print('✅ Food logs synced for $syncedDays days');
    } catch (e) {
      print('❌ Error syncing food logs: $e');
    }
  }

  // Sync Daily Tasks for the last 30 days
  Future<void> _syncDailyTasks(String uid) async {
    try {
      print('📋 ===== STARTING DAILY TASKS SYNC =====');
      print('📋 User ID: $uid');

      final now = DateTime.now();
      final todayString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      print('📋 Today\'s date: $todayString');

      int syncedDays = 0;

      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        print('\n📋 --- Processing date: $dateString (day $i) ---');

        try {
          final taskData = await _firestoreService.getDailyTask(date);

          if (taskData != null) {
            print('📋 ✅ Raw task data found for $dateString:');
            print('   - Data type: ${taskData.runtimeType}');
            print('   - Keys: ${taskData.keys.toList()}');

            // Log each task in detail
            taskData.forEach((key, value) {
              print('   - $key: $value (${value.runtimeType})');
              if (value is Map) {
                value.forEach((subKey, subValue) {
                  print('     - $subKey: $subValue (${subValue.runtimeType})');
                });
              }
            });

            // แปลง Firestore Timestamps เป็น ISO strings อีกครั้งเพื่อความแน่ใจ
            final processedTaskData = _processFirestoreData(taskData);
            print('📋 Processed task data for saving:');
            print('   - Processed keys: ${processedTaskData.keys.toList()}');
            processedTaskData.forEach((key, value) {
              print('   - $key: $value (${value.runtimeType})');
            });

            await _databaseService.saveDailyTask(uid, processedTaskData, date);
            syncedDays++;
            print('✅ Successfully synced daily task for $dateString');
          } else {
            print(
              '📭 No daily task found for $dateString from FirestoreService',
            );
          }
        } catch (e) {
          print('⚠️ Error syncing daily tasks for $dateString: $e');

          // Try to get raw data and manually process it
          try {
            print(
              '🔄 Attempting manual Firestore data retrieval for $dateString',
            );
            final docPath =
                'users/${_auth.currentUser?.uid}/dailyTasks/$dateString';
            print('🔄 Document path: $docPath');

            final rawData = await FirebaseFirestore.instance
                .collection('users')
                .doc(_auth.currentUser?.uid)
                .collection('dailyTasks')
                .doc(dateString)
                .get();

            print('🔄 Document exists: ${rawData.exists}');
            print('🔄 Document data: ${rawData.data()}');

            if (rawData.exists && rawData.data() != null) {
              final manualProcessedData = _processFirestoreData(
                rawData.data()!,
              );
              print('🔄 Manual processed data: $manualProcessedData');

              await _databaseService.saveDailyTask(
                uid,
                manualProcessedData,
                date,
              );
              syncedDays++;
              print('✅ Manually synced daily task for $dateString');
            } else {
              print('📭 No document found at path: $docPath');
            }
          } catch (manualError) {
            print('❌ Manual sync also failed for $dateString: $manualError');
          }
        }
      }

      print('\n📋 ===== DAILY TASKS SYNC COMPLETED =====');
      print('📋 Total synced days: $syncedDays/30');
    } catch (e) {
      print('❌ Critical error in daily tasks sync: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Helper function to process Firestore data and convert Timestamps
  Map<String, dynamic> _processFirestoreData(Map<String, dynamic> data) {
    final processedData = <String, dynamic>{};

    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        processedData[entry.key] = (entry.value as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (entry.value is Map<String, dynamic>) {
        processedData[entry.key] = _processFirestoreData(entry.value);
      } else if (entry.value is List) {
        processedData[entry.key] = (entry.value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _processFirestoreData(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else {
            return item;
          }
        }).toList();
      } else {
        processedData[entry.key] = entry.value;
      }
    }

    return processedData;
  }

  // ตรวจสอบข้อมูลใน SQLite
  Future<Map<String, dynamic>> getLocalDataStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'error': 'No authenticated user'};

      final counts = await _databaseService.getDataCounts(user.uid);
      final userProfile = await _databaseService.getUserProfile(user.uid);

      return {
        'uid': user.uid,
        'hasUserProfile': userProfile != null,
        'profileCompleted': userProfile?['profileCompleted'] ?? false,
        'dataCounts': counts,
        'lastSyncCheck': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // บังคับ sync ข้อมูลใหม่
  Future<bool> forceSyncFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('🔄 Force syncing from Firestore...');

      // Try to sync today's food logs specifically
      final today = DateTime.now();
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final todayStringNoZero = "${today.year}-${today.month}-${today.day}";

      print('🍽️ Trying to sync food logs for $todayString');
      final todayFoodLogs = await _firestoreService.getFoodLogsForDate(
        todayString,
      );
      print('🍽️ Found ${todayFoodLogs.length} meals for $todayString');

      if (todayFoodLogs.isEmpty && todayStringNoZero != todayString) {
        print('🍽️ Trying alternate format: $todayStringNoZero');
        final altFoodLogs = await _firestoreService.getFoodLogsForDate(
          todayStringNoZero,
        );
        print('🍽️ Found ${altFoodLogs.length} meals for $todayStringNoZero');

        if (altFoodLogs.isNotEmpty) {
          print('✅ Processing ${altFoodLogs.length} meals...');
          await _databaseService.clearFoodLogsForDate(
            uid: user.uid,
            date: todayString,
          );

          for (final meal in altFoodLogs) {
            final processedMeal = _processFirestoreData(meal);
            await _databaseService.addFoodLog(
              uid: user.uid,
              date: todayString,
              mealData: processedMeal,
            );
          }
          print('✅ Successfully force synced ${altFoodLogs.length} meals');
        }
      }

      // Clear existing data first
      // await _databaseService.clearAllData();

      // Sync fresh data
      return await syncUserDataFromFirestore();
    } catch (e) {
      print('❌ Force sync failed: $e');
      return false;
    }
  }

  // Auto sync when app starts (if needed)
  Future<void> performInitialSyncIfNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if we have user profile in SQLite
      final userProfile = await _databaseService.getUserProfile(user.uid);

      if (userProfile == null) {
        print('🔄 No local user profile found, starting initial sync...');
        await syncUserDataFromFirestore();
      } else {
        print('✅ Local data exists, skipping initial sync');
      }
    } catch (e) {
      print('❌ Initial sync check failed: $e');
    }
  }

  // Sync specific date food logs
  Future<void> syncFoodLogsForDate(String date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final foodLogs = await _firestoreService.getFoodLogsForDate(date);

      // Clear existing logs for this date
      await _databaseService.clearFoodLogsForDate(uid: user.uid, date: date);

      // Add new logs
      for (final meal in foodLogs) {
        await _databaseService.addFoodLog(
          uid: user.uid,
          date: date,
          mealData: meal,
        );
      }

      print('✅ Food logs synced for date: $date');
    } catch (e) {
      print('❌ Error syncing food logs for date $date: $e');
    }
  }
}
