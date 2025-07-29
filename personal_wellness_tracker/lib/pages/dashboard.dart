import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  Widget _buildDailyTaskItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isTablet ? 50 : 40, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricItem({
    required String label,
    required String value,
    required Color color,
    Color labelColor = Colors.grey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            const Text(
              '6510110165',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: isTablet ? 200 : 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: isTablet ? 100 : 80,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Bar
            Text(
              'บันทึกมาแล้ว (7 วัน)',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: 7 / 14,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '14 วัน',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Center(
              child: Text(
                'สิ่งที่ต้องทำประจำวัน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildDailyTaskItem(
                    icon: Icons.track_changes,
                    label: 'ติดตามประจำวัน',
                    onTap: () => print('Daily Tracking tapped'),
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.fastfood,
                    label: 'บันทึกอาหาร',
                    onTap: () => print('Record Food tapped'),
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.bar_chart,
                    label: 'ผลความก้าวหน้า',
                    onTap: () => print('Progress Results tapped'),
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 2, color: Colors.grey),

            const Center(
              child: Text(
                "สุขภาพประจำวัน",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 20.0,
                    runSpacing: 15.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHealthMetricItem(
                        label: "ชื่อผู้ใช้",
                        value: "6510110165",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "อายุ",
                        value: "1000 ปี",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "น้ำหนัก",
                        value: "65 kg",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "ส่วนสูง",
                        value: "175 cm",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "ค่า BMI",
                        value: "21.2 (ปกติ)",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "ความดันโลหิต",
                        value: "120/80 mmHg",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "อัตราเต้นหัวใจ",
                        value: "75 bpm",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "อาหาร",
                        value: "2000 kcal",
                        color: Colors.black87,
                      ),
                      _buildHealthMetricItem(
                        label: "อารมณ์",
                        value: "😊😊😊",
                        color: Colors.black87,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ผลการประเมิน: ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "สุขภาพดี",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
