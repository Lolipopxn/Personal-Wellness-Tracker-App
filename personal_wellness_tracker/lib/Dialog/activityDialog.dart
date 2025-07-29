import 'package:flutter/material.dart';

class ActivitySection extends StatefulWidget {
  const ActivitySection({super.key});

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  List<String> activities = [];

  void showAddActivityDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("เพิ่มกิจกรรม"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "ชื่อกิจกรรม",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  activities.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: showAddActivityDialog,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.blueAccent.withAlpha(255),
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.black),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Add Activity',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card.filled(
                      color: Colors.white,
                      shadowColor: Colors.black,
                      elevation: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 15),
                              Icon(Icons.check, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text(activity, style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                activities.removeAt(index);
                              });
                            },
                          ),
                        ],
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
