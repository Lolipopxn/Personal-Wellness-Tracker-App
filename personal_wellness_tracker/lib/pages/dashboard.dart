import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  Widget _buildDailyTaskItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              border: Border.all(color: Colors.grey, width: 1), // Background for the icon
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ), // Added style for consistency
          ),
        ],
      ),
    );
  }

  // New helper widget to build a health metric item
  Widget _buildHealthMetricItem({
    required String label,
    required String value,
    required Color color, // Default icon color
    Color labelColor = Colors.grey, // Default label color
    // Color valueColor = Colors.black87,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
      children: [
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow
        title: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () {
                // Handle profile icon tap
              },
            ),
            const SizedBox(width: 8),
            const Text(
              '6510110165', // Replace with dynamic username
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
            onPressed: () {
              // Handle notifications icon tap
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {
              // Handle settings icon tap
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder Section
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Bar Section
            Text(
              'บันทึกมาแล้ว (7 วัน)', // "Recorded (7 days)"
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 7 / 14, // Example: 7 out of 14 days
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
                  '14 วัน', // "14 days"
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Daily Tasks Section
            const Text(
              'สิ่งที่ต้องทำประจำวัน', // "Things to do daily"
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildDailyTaskItem(
                  icon: Icons.track_changes, // Example icon for tracking
                  label: 'ติดตามประจำวัน', // "Daily Tracking"
                  onTap: () {
                    print('Daily Tracking tapped');
                  },
                ),
                _buildDailyTaskItem(
                  icon: Icons.fastfood, // Example icon for food
                  label: 'บันทึกอาหาร', // "Record Food"
                  onTap: () {
                    print('Record Food tapped');
                  },
                ),
                _buildDailyTaskItem(
                  icon: Icons.bar_chart, // Example icon for progress
                  label: 'ผลความก้าวหน้า', // "Progress Results"
                  onTap: () {
                    print('Progress Results tapped');
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Divider(
              thickness: 2,
              color: Colors.grey,
              indent: 1,
              endIndent: 1, 
            ),
            // Daily Health Section (Updated)
            const Text(
              "สุขภาพประจำวัน", // "Daily Health"
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all( 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                    spacing: 20.0, // Horizontal space between items
                    runSpacing: 15.0, // Vertical space between lines
                    alignment: WrapAlignment.start, // Align items to the start
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
                  ),
                  
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Center the text
                      children: [
                        const Text("ผลการประเมิน: ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8), // Space between icon and text
                        const Text(
                          "สุขภาพดี", // "Healthy"
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
