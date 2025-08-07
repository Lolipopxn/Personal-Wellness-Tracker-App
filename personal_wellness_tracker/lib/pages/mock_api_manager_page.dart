import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';

class MockApiManagerPage extends StatefulWidget {
  const MockApiManagerPage({super.key});

  @override
  State<MockApiManagerPage> createState() => _MockApiManagerPageState();
}

class _MockApiManagerPageState extends State<MockApiManagerPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _mockApiData = [];

  @override
  void initState() {
    super.initState();
    _loadMockApiData();
  }

  Future<void> _loadMockApiData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังโหลดข้อมูล...';
    });

    try {
      final data = await NutritionService.getAllMockAPIData();
      setState(() {
        _mockApiData = data;
        _statusMessage = 'โหลดข้อมูลสำเร็จ: ${data.length} รายการ';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังทดสอบการเชื่อมต่อ...';
    });

    try {
      final isConnected = await NutritionService.testMockAPIConnection();
      setState(() {
        _statusMessage = isConnected 
            ? 'เชื่อมต่อ MockAPI สำเร็จ!' 
            : 'ไม่สามารถเชื่อมต่อ MockAPI ได้';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearMockAPI() async {
    // แสดง dialog ยืนยัน
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูล'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะลบข้อมูลทั้งหมดใน MockAPI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'กำลังลบข้อมูล...';
      });

      try {
        final success = await NutritionService.clearMockAPI();
        setState(() {
          _statusMessage = success 
              ? 'ลบข้อมูลสำเร็จ!' 
              : 'ไม่สามารถลบข้อมูลได้';
          _isLoading = false;
        });
        
        if (success) {
          await _loadMockApiData(); // โหลดข้อมูลใหม่
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'เกิดข้อผิดพลาด: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการ MockAPI'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ข้อมูลสถานะ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'สถานะ MockAPI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ปุ่มจัดการ
            const Text(
              'การจัดการ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: const Icon(Icons.wifi_outlined),
                    label: const Text('ทดสอบการเชื่อมต่อ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadMockApiData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('รีเฟรชข้อมูล'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearMockAPI,
                icon: const Icon(Icons.delete_forever),
                label: const Text('ลบข้อมูลทั้งหมด'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // รายการข้อมูล
            Row(
              children: [
                const Text(
                  'ข้อมูลใน MockAPI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (_mockApiData.isNotEmpty)
                  Text(
                    '${_mockApiData.length} รายการ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // แสดงข้อมูล
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _mockApiData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ไม่มีข้อมูลใน MockAPI',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _mockApiData.length,
                          itemBuilder: (context, index) {
                            final item = _mockApiData[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['name'] ?? 'ไม่มีชื่อ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item['calories']} cal • P: ${item['protein']}g • C: ${item['carb'] ?? item['carbs']}g • F: ${item['fat']}g',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  'ID: ${item['id']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
