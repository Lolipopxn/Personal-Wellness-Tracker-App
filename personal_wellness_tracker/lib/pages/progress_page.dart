import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<bool> _isSelected = [true, false, false];

  final Map<String, List<FlSpot>> _sleepChartData = {
    'daily': const [
      FlSpot(0, 7.5),
      FlSpot(1, 8.0),
      FlSpot(2, 6.5),
      FlSpot(3, 7.5),
      FlSpot(4, 8.0),
      FlSpot(5, 7.0),
      FlSpot(6, 8.5),
    ],
    'weekly': const [
      FlSpot(0, 7.2),
      FlSpot(1, 7.8),
      FlSpot(2, 7.5),
      FlSpot(3, 8.0),
    ],
    'monthly': const [
      FlSpot(0, 7.5),
      FlSpot(1, 7.8),
      FlSpot(2, 7.2),
      FlSpot(3, 8.0),
      FlSpot(4, 7.6),
      FlSpot(5, 8.2),
    ],
  };

  final Map<String, List<FlSpot>> _exerciseChartData = {
    'daily': const [
      FlSpot(0, 30),
      FlSpot(1, 45),
      FlSpot(2, 0),
      FlSpot(3, 60),
      FlSpot(4, 30),
      FlSpot(5, 90),
      FlSpot(6, 45),
    ],
    'weekly': const [
      FlSpot(0, 180),
      FlSpot(1, 240),
      FlSpot(2, 210),
      FlSpot(3, 300),
    ],
    'monthly': const [
      FlSpot(0, 720),
      FlSpot(1, 900),
      FlSpot(2, 840),
      FlSpot(3, 1080),
      FlSpot(4, 960),
      FlSpot(5, 1200),
    ],
  };

  final Map<String, List<BarChartGroupData>> _waterChartData = {
    'daily': [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 6, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 8, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 5, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: 7, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [BarChartRodData(toY: 9, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [BarChartRodData(toY: 6, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 6,
        barRods: [BarChartRodData(toY: 8, color: Colors.blue)],
      ),
    ],
    'weekly': [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 42, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 49, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 45, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: 52, color: Colors.blue)],
      ),
    ],
    'monthly': [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 180, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 210, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 195, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: 225, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [BarChartRodData(toY: 200, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [BarChartRodData(toY: 240, color: Colors.blue)],
      ),
    ],
  };

  // Mock Data for calories (kcal)
  final Map<String, List<FlSpot>> _caloriesChartData = {
    'daily': const [
      FlSpot(0, 1800),
      FlSpot(1, 2100),
      FlSpot(2, 1950),
      FlSpot(3, 2200),
      FlSpot(4, 1850),
      FlSpot(5, 2300),
      FlSpot(6, 2000),
    ],
    'weekly': const [
      FlSpot(0, 14000),
      FlSpot(1, 14700),
      FlSpot(2, 15200),
      FlSpot(3, 15800),
    ],
    'monthly': const [
      FlSpot(0, 58000),
      FlSpot(1, 62000),
      FlSpot(2, 59500),
      FlSpot(3, 65000),
      FlSpot(4, 61000),
      FlSpot(5, 67000),
    ],
  };

  final Map<String, Map<String, String>> _mockStatsData = {
    'daily': {
      'title': 'เป้าหมายวันนี้',
      'completion': '3/5 สำเร็จ',
      'percentage': '60%',
      'comparison': '+5% จากเมื่อวาน',
    },
    'weekly': {
      'title': 'เป้าหมายสัปดาห์นี้',
      'completion': '25/35 สำเร็จ',
      'percentage': '71%',
      'comparison': '-10% จากสัปดาห์ที่แล้ว',
    },
    'monthly': {
      'title': 'เป้าหมายเดือนนี้',
      'completion': '100/150 สำเร็จ',
      'percentage': '67%',
      'comparison': '+15% จากเดือนที่แล้ว',
    },
  };

  String _currentView = 'daily';

  // Function to build the bottom titles for the chart based on the time period
  Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    String text = '';

    if (_currentView == 'daily') {
      final days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
      text = days[value.toInt()];
    } else if (_currentView == 'weekly') {
      text = 'W${value.toInt() + 1}';
    } else if (_currentView == 'monthly') {
      final months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.'];
      text = months[value.toInt()];
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required Widget chart,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  void _updateView(int index) {
    setState(() {
      for (int i = 0; i < _isSelected.length; i++) {
        _isSelected[i] = i == index;
      }
      if (index == 0) _currentView = 'daily';
      if (index == 1) _currentView = 'weekly';
      if (index == 2) _currentView = 'monthly';
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _mockStatsData[_currentView]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ความก้าวหน้าของฉัน'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Time period selector
          Center(
            child: ToggleButtons(
              isSelected: _isSelected,
              onPressed: _updateView,
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: Colors.white,
              fillColor: Colors.teal,
              color: Colors.teal,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('รายวัน'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('รายสัปดาห์'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('รายเดือน'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ความสำเร็จ:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        stats['completion']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ความคืบหน้า:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value:
                        double.parse(stats['percentage']!.replaceAll('%', '')) /
                        100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${stats['percentage']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // การเปรียบเทียบช่วงเวลาก่อนหน้า
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.compare_arrows,
                color: Colors.blue,
                size: 30,
              ),
              title: const Text('เปรียบเทียบกับช่วงเวลาก่อนหน้า'),
              subtitle: Text(
                stats['comparison']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: stats['comparison']!.startsWith('+')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Sleep Chart
          _buildChartCard(
            title: 'การนอนหลับ',
            unit: 'ชั่วโมง',
            icon: Icons.bedtime,
            color: Colors.indigo,
            chart: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: getBottomTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _sleepChartData[_currentView] ?? [],
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigo.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercise Chart
          _buildChartCard(
            title: 'การออกกำลังกาย',
            unit: 'นาที',
            icon: Icons.fitness_center,
            color: Colors.orange,
            chart: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: getBottomTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _exerciseChartData[_currentView] ?? [],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Water Intake Chart
          _buildChartCard(
            title: 'การดื่มน้ำ',
            unit: 'แก้ว',
            icon: Icons.local_drink,
            color: Colors.blue,
            chart: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _currentView == 'daily'
                    ? 10
                    : _currentView == 'weekly'
                    ? 60
                    : 250,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getBottomTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _waterChartData[_currentView] ?? [],
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Calories Chart
          _buildChartCard(
            title: 'แคลอรี่',
            unit: 'kcal',
            icon: Icons.restaurant,
            color: Colors.green,
            chart: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: getBottomTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _caloriesChartData[_currentView] ?? [],
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
