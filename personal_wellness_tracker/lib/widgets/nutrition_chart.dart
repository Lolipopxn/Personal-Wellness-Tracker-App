import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/nutrition_service.dart';

class NutritionChart extends StatelessWidget {
  final NutritionData nutritionData;
  final double size;

  const NutritionChart({
    super.key,
    required this.nutritionData,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: size * 0.25,
              sections: _buildSections(),
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // สามารถเพิ่ม interaction ได้ที่นี่
                },
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${nutritionData.calories.toInt()}',
                  style: TextStyle(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: size * 0.07,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    // คำนวณน้ำหนักของแต่ละสารอาหาร (ใช้กรัมแทนแคลอรี่เพื่อให้ครบถ้วน)
    double totalWeight = nutritionData.protein + nutritionData.carbs + nutritionData.fat + 
                        nutritionData.fiber + nutritionData.sugar;

    // ป้องกันการหารด้วย 0
    if (totalWeight == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300]!,
          value: 100,
          title: '',
          radius: size * 0.15,
        ),
      ];
    }

    // สร้าง sections สำหรับทุกประเภทสารอาหาร
    List<PieChartSectionData> sections = [];
    
    // โปรตีน (สีแดง)
    if (nutritionData.protein > 0) {
      sections.add(PieChartSectionData(
        color: Colors.red[400]!,
        value: (nutritionData.protein / totalWeight * 100),
        title: '',
        radius: size * 0.15,
      ));
    }
    
    // คาร์โบไฮเดรต (สีฟ้า)
    if (nutritionData.carbs > 0) {
      sections.add(PieChartSectionData(
        color: Colors.blue[400]!,
        value: (nutritionData.carbs / totalWeight * 100),
        title: '',
        radius: size * 0.15,
      ));
    }
    
    // ไขมัน (สีส้ม)
    if (nutritionData.fat > 0) {
      sections.add(PieChartSectionData(
        color: Colors.orange[400]!,
        value: (nutritionData.fat / totalWeight * 100),
        title: '',
        radius: size * 0.15,
      ));
    }
    
    // ใยอาหาร (สีเขียว)
    if (nutritionData.fiber > 0) {
      sections.add(PieChartSectionData(
        color: Colors.green[400]!,
        value: (nutritionData.fiber / totalWeight * 100),
        title: '',
        radius: size * 0.15,
      ));
    }
    
    // น้ำตาล (สีชมพู)
    if (nutritionData.sugar > 0) {
      sections.add(PieChartSectionData(
        color: Colors.pink[400]!,
        value: (nutritionData.sugar / totalWeight * 100),
        title: '',
        radius: size * 0.15,
      ));
    }

    return sections;
  }
}

class NutritionLegend extends StatelessWidget {
  final NutritionData nutritionData;

  const NutritionLegend({super.key, required this.nutritionData});

  @override
  Widget build(BuildContext context) {
    // คำนวณน้ำหนักรวมและเปอร์เซ็นต์
    double totalWeight = nutritionData.protein + nutritionData.carbs + nutritionData.fat + 
                        nutritionData.fiber + nutritionData.sugar;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // สารอาหารหลัก (ในกราฟ)
        Text(
          'องค์ประกอบทางโภชนาการ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        _buildLegendItem(
          'โปรตีน',
          '${nutritionData.protein.toStringAsFixed(1)}g',
          '${totalWeight > 0 ? (nutritionData.protein / totalWeight * 100).toStringAsFixed(0) : 0}%',
          Colors.red[400]!,
        ),
        const SizedBox(height: 3),
        _buildLegendItem(
          'คาร์บ',
          '${nutritionData.carbs.toStringAsFixed(1)}g',
          '${totalWeight > 0 ? (nutritionData.carbs / totalWeight * 100).toStringAsFixed(0) : 0}%',
          Colors.blue[400]!,
        ),
        const SizedBox(height: 3),
        _buildLegendItem(
          'ไขมัน',
          '${nutritionData.fat.toStringAsFixed(1)}g',
          '${totalWeight > 0 ? (nutritionData.fat / totalWeight * 100).toStringAsFixed(0) : 0}%',
          Colors.orange[400]!,
        ),
        if (nutritionData.fiber > 0) ...[
          const SizedBox(height: 3),
          _buildLegendItem(
            'ใยอาหาร',
            '${nutritionData.fiber.toStringAsFixed(1)}g',
            '${totalWeight > 0 ? (nutritionData.fiber / totalWeight * 100).toStringAsFixed(0) : 0}%',
            Colors.green[400]!,
          ),
        ],
        if (nutritionData.sugar > 0) ...[
          const SizedBox(height: 3),
          _buildLegendItem(
            'น้ำตาล',
            '${nutritionData.sugar.toStringAsFixed(1)}g',
            '${totalWeight > 0 ? (nutritionData.sugar / totalWeight * 100).toStringAsFixed(0) : 0}%',
            Colors.pink[400]!,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, String percentage, Color color, {bool showDot = true}) {
    return Row(
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ] else ...[
          const SizedBox(width: 14),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: showDot ? color : Colors.green[600],
              ),
            ),
            if (percentage.isNotEmpty)
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class NutritionInfoCard extends StatelessWidget {
  final NutritionData? nutritionData;
  final int fallbackCalories;

  const NutritionInfoCard({
    super.key,
    this.nutritionData,
    required this.fallbackCalories,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealData = nutritionData != null;
    
    // ใช้ข้อมูลจาก API ถ้ามี หรือสร้างข้อมูลเริ่มต้นถ้าไม่มี
    final data = hasRealData 
        ? nutritionData! 
        : NutritionService.getDefaultNutrition(fallbackCalories);

    return Container(
      margin: const EdgeInsets.only(left: 12, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasRealData ? Colors.green[200]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          NutritionChart(nutritionData: data, size: 80),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasRealData ? 'ข้อมูลจาก API' : 'ข้อมูลประมาณการ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasRealData ? Colors.green[700] : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      hasRealData ? Icons.verified : Icons.info_outline,
                      size: 14,
                      color: hasRealData ? Colors.green[600] : Colors.orange[600],
                    ),
                  ],
                ),
                if (!hasRealData)
                  Text(
                    'คำนวณจากแคลอรี่',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 8),
                NutritionLegend(nutritionData: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
